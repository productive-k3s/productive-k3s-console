#define _GNU_SOURCE

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <linux/landlock.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/prctl.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <unistd.h>

#ifndef CONFIG_ROOT
#define CONFIG_ROOT "/home/pk3s/config"
#endif
#define MAX_DOCUMENT_SIZE (1024U * 1024U)

#ifndef LANDLOCK_ACCESS_FS_REFER
#define LANDLOCK_ACCESS_FS_REFER (1ULL << 13)
#endif
#ifndef LANDLOCK_ACCESS_FS_TRUNCATE
#define LANDLOCK_ACCESS_FS_TRUNCATE (1ULL << 14)
#endif

static char current_rel[PATH_MAX] = "";

static int landlock_create_ruleset(const struct landlock_ruleset_attr *attr, size_t size, unsigned int flags) {
    return (int)syscall(__NR_landlock_create_ruleset, attr, size, flags);
}

static int landlock_add_rule(int ruleset_fd, enum landlock_rule_type type,
                             const void *attr, unsigned int flags) {
    return (int)syscall(__NR_landlock_add_rule, ruleset_fd, type, attr, flags);
}

static int landlock_restrict_self(int ruleset_fd, unsigned int flags) {
    return (int)syscall(__NR_landlock_restrict_self, ruleset_fd, flags);
}

static bool apply_filesystem_jail(void) {
    __u64 handled_access =
        LANDLOCK_ACCESS_FS_EXECUTE |
        LANDLOCK_ACCESS_FS_WRITE_FILE |
        LANDLOCK_ACCESS_FS_READ_FILE |
        LANDLOCK_ACCESS_FS_READ_DIR |
        LANDLOCK_ACCESS_FS_REMOVE_DIR |
        LANDLOCK_ACCESS_FS_REMOVE_FILE |
        LANDLOCK_ACCESS_FS_MAKE_CHAR |
        LANDLOCK_ACCESS_FS_MAKE_DIR |
        LANDLOCK_ACCESS_FS_MAKE_REG |
        LANDLOCK_ACCESS_FS_MAKE_SOCK |
        LANDLOCK_ACCESS_FS_MAKE_FIFO |
        LANDLOCK_ACCESS_FS_MAKE_BLOCK |
        LANDLOCK_ACCESS_FS_MAKE_SYM;
    __u64 allowed_access =
        LANDLOCK_ACCESS_FS_WRITE_FILE |
        LANDLOCK_ACCESS_FS_READ_FILE |
        LANDLOCK_ACCESS_FS_READ_DIR |
        LANDLOCK_ACCESS_FS_REMOVE_DIR |
        LANDLOCK_ACCESS_FS_REMOVE_FILE |
        LANDLOCK_ACCESS_FS_MAKE_DIR |
        LANDLOCK_ACCESS_FS_MAKE_REG;
    struct landlock_ruleset_attr ruleset = {0};
    struct landlock_path_beneath_attr path_rule = {0};
    int abi;
    int ruleset_fd;
    int config_fd;

    abi = landlock_create_ruleset(NULL, 0, LANDLOCK_CREATE_RULESET_VERSION);
    if (abi < 1) {
        fputs("Landlock is unavailable; refusing to start the Config workspace.\n", stderr);
        return false;
    }
    if (abi >= 2) {
        handled_access |= LANDLOCK_ACCESS_FS_REFER;
        allowed_access |= LANDLOCK_ACCESS_FS_REFER;
    }
    if (abi >= 3) {
        handled_access |= LANDLOCK_ACCESS_FS_TRUNCATE;
        allowed_access |= LANDLOCK_ACCESS_FS_TRUNCATE;
    }
    ruleset.handled_access_fs = handled_access;
    ruleset_fd = landlock_create_ruleset(&ruleset, sizeof(ruleset), 0);
    if (ruleset_fd < 0) {
        perror("landlock ruleset");
        return false;
    }
    config_fd = open(CONFIG_ROOT, O_PATH | O_CLOEXEC);
    if (config_fd < 0) {
        perror("config workspace");
        close(ruleset_fd);
        return false;
    }
    path_rule.allowed_access = allowed_access;
    path_rule.parent_fd = config_fd;
    if (landlock_add_rule(ruleset_fd, LANDLOCK_RULE_PATH_BENEATH, &path_rule, 0) != 0 ||
        prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0) != 0 ||
        landlock_restrict_self(ruleset_fd, 0) != 0) {
        perror("landlock restriction");
        close(config_fd);
        close(ruleset_fd);
        return false;
    }
    close(config_fd);
    close(ruleset_fd);
    return true;
}


static char *trim(char *value) {
    char *end;

    while (*value == ' ' || *value == '\t') {
        value++;
    }
    end = value + strlen(value);
    while (end > value && (end[-1] == ' ' || end[-1] == '\t' || end[-1] == '\n' || end[-1] == '\r')) {
        end--;
    }
    *end = '\0';
    return value;
}

static bool normalize_relative(const char *input, char *output, size_t output_size) {
    char combined[PATH_MAX];
    char scratch[PATH_MAX];
    char *saveptr = NULL;
    char *part;
    size_t used = 0;

    if (input == NULL || input[0] == '\0' || strcmp(input, ".") == 0) {
        if (snprintf(combined, sizeof(combined), "%s", current_rel) >= (int)sizeof(combined)) {
            return false;
        }
    } else {
        if (input[0] == '/') {
            fprintf(stderr, "Absolute paths are not allowed.\n");
            return false;
        }
        if (current_rel[0] == '\0') {
            if (snprintf(combined, sizeof(combined), "%s", input) >= (int)sizeof(combined)) {
                return false;
            }
        } else if (snprintf(combined, sizeof(combined), "%s/%s", current_rel, input) >= (int)sizeof(combined)) {
            return false;
        }
    }

    if (snprintf(scratch, sizeof(scratch), "%s", combined) >= (int)sizeof(scratch)) {
        return false;
    }
    output[0] = '\0';
    part = strtok_r(scratch, "/", &saveptr);
    while (part != NULL) {
        size_t part_length = strlen(part);
        if (strcmp(part, ".") == 0 || part_length == 0) {
            part = strtok_r(NULL, "/", &saveptr);
            continue;
        }
        if (strcmp(part, "..") == 0) {
            fprintf(stderr, "Parent traversal is not allowed.\n");
            return false;
        }
        if (part_length > NAME_MAX || used + part_length + (used == 0 ? 1 : 2) > output_size) {
            fprintf(stderr, "Path is too long.\n");
            return false;
        }
        if (used > 0) {
            output[used++] = '/';
        }
        memcpy(output + used, part, part_length);
        used += part_length;
        output[used] = '\0';
        part = strtok_r(NULL, "/", &saveptr);
    }
    return true;
}

static bool verify_components(const char *relative, bool allow_missing_leaf) {
    char scratch[PATH_MAX];
    char candidate[PATH_MAX] = CONFIG_ROOT;
    char *saveptr = NULL;
    char *part;
    struct stat info;

    if (relative[0] == '\0') {
        return true;
    }
    if (snprintf(scratch, sizeof(scratch), "%s", relative) >= (int)sizeof(scratch)) {
        return false;
    }
    part = strtok_r(scratch, "/", &saveptr);
    while (part != NULL) {
        char *next = strtok_r(NULL, "/", &saveptr);
        size_t used = strlen(candidate);
        if (snprintf(candidate + used, sizeof(candidate) - used, "/%s", part) >= (int)(sizeof(candidate) - used)) {
            return false;
        }
        if (lstat(candidate, &info) != 0) {
            if (errno == ENOENT && allow_missing_leaf && next == NULL) {
                return true;
            }
            fprintf(stderr, "Path is not available: %s\n", relative);
            return false;
        }
        if (S_ISLNK(info.st_mode)) {
            fprintf(stderr, "Symbolic links are not allowed: %s\n", relative);
            return false;
        }
        if (next != NULL && !S_ISDIR(info.st_mode)) {
            fprintf(stderr, "Path component is not a directory: %s\n", part);
            return false;
        }
        part = next;
    }
    return true;
}

static bool resolve_path(const char *input, bool allow_missing_leaf, char *absolute, size_t absolute_size,
                         char *relative, size_t relative_size) {
    if (!normalize_relative(input, relative, relative_size)) {
        return false;
    }
    if (!verify_components(relative, allow_missing_leaf)) {
        return false;
    }
    if (relative[0] == '\0') {
        return snprintf(absolute, absolute_size, "%s", CONFIG_ROOT) < (int)absolute_size;
    }
    return snprintf(absolute, absolute_size, "%s/%s", CONFIG_ROOT, relative) < (int)absolute_size;
}

static void print_help(void) {
    puts("Commands:");
    puts("  help                Show this command list");
    puts("  pwd                 Show the current configuration path");
    puts("  ls [path]           List files and directories");
    puts("  cd [path]           Enter a child directory; '..' is never accepted");
    puts("  view <file>         Display a text file");
    puts("  edit <file>         Replace or create a text file atomically");
    puts("  touch <file>        Create an empty private file");
    puts("  mkdir <directory>   Create a private directory");
    puts("  rm <file>           Remove a regular file");
    puts("  rmdir <directory>   Remove an empty directory");
    puts("  exit                Return to the Console selector");
}

static void command_pwd(void) {
    if (current_rel[0] == '\0') {
        puts(CONFIG_ROOT);
    } else {
        printf("%s/%s\n", CONFIG_ROOT, current_rel);
    }
}

static void command_ls(const char *argument) {
    char absolute[PATH_MAX];
    char relative[PATH_MAX];
    struct stat info;
    DIR *directory;
    struct dirent *entry;

    if (!resolve_path(argument, false, absolute, sizeof(absolute), relative, sizeof(relative))) {
        return;
    }
    if (lstat(absolute, &info) != 0) {
        perror("ls");
        return;
    }
    if (!S_ISDIR(info.st_mode)) {
        printf("%s\n", relative);
        return;
    }
    directory = opendir(absolute);
    if (directory == NULL) {
        perror("ls");
        return;
    }
    while ((entry = readdir(directory)) != NULL) {
        char entry_path[PATH_MAX];
        struct stat entry_info;
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        if (snprintf(entry_path, sizeof(entry_path), "%s/%s", absolute, entry->d_name) >= (int)sizeof(entry_path)) {
            continue;
        }
        if (lstat(entry_path, &entry_info) == 0 && S_ISDIR(entry_info.st_mode)) {
            printf("%s/\n", entry->d_name);
        } else {
            printf("%s\n", entry->d_name);
        }
    }
    closedir(directory);
}

static void command_cd(const char *argument) {
    char absolute[PATH_MAX];
    char relative[PATH_MAX];
    struct stat info;

    if (!resolve_path(argument, false, absolute, sizeof(absolute), relative, sizeof(relative))) {
        return;
    }
    if (lstat(absolute, &info) != 0 || !S_ISDIR(info.st_mode)) {
        fprintf(stderr, "Not a directory: %s\n", argument);
        return;
    }
    snprintf(current_rel, sizeof(current_rel), "%s", relative);
}

static void command_view(const char *argument) {
    char absolute[PATH_MAX];
    char relative[PATH_MAX];
    struct stat info;
    FILE *file;
    char buffer[4096];
    size_t count;

    if (argument[0] == '\0') {
        fputs("view requires a file.\n", stderr);
        return;
    }
    if (!resolve_path(argument, false, absolute, sizeof(absolute), relative, sizeof(relative))) {
        return;
    }
    if (lstat(absolute, &info) != 0 || !S_ISREG(info.st_mode)) {
        fprintf(stderr, "Not a regular file: %s\n", argument);
        return;
    }
    if ((size_t)info.st_size > MAX_DOCUMENT_SIZE) {
        fputs("File exceeds the 1 MiB workspace limit.\n", stderr);
        return;
    }
    file = fopen(absolute, "r");
    if (file == NULL) {
        perror("view");
        return;
    }
    while ((count = fread(buffer, 1, sizeof(buffer), file)) > 0) {
        fwrite(buffer, 1, count, stdout);
    }
    if (info.st_size > 0) {
        putchar('\n');
    }
    fclose(file);
}

static void command_edit(const char *argument) {
    char absolute[PATH_MAX];
    char relative[PATH_MAX];
    char temporary[PATH_MAX];
    char *line = NULL;
    size_t line_capacity = 0;
    char *content = NULL;
    size_t content_size = 0;
    size_t content_capacity = 0;
    ssize_t line_size;
    int descriptor;
    FILE *file;

    if (argument[0] == '\0') {
        fputs("edit requires a file.\n", stderr);
        return;
    }
    if (!resolve_path(argument, true, absolute, sizeof(absolute), relative, sizeof(relative))) {
        return;
    }
    if (access(absolute, F_OK) == 0) {
        struct stat info;
        if (lstat(absolute, &info) != 0 || !S_ISREG(info.st_mode)) {
            fprintf(stderr, "Not a regular file: %s\n", argument);
            return;
        }
        puts("Current content:");
        command_view(argument);
    }
    puts("Enter replacement content. Use .save on its own line to save or .cancel to abort.");
    while ((line_size = getline(&line, &line_capacity, stdin)) >= 0) {
        if (strcmp(line, ".save\n") == 0 || strcmp(line, ".save") == 0) {
            break;
        }
        if (strcmp(line, ".cancel\n") == 0 || strcmp(line, ".cancel") == 0) {
            free(line);
            free(content);
            puts("Edit cancelled.");
            return;
        }
        if (content_size + (size_t)line_size > MAX_DOCUMENT_SIZE) {
            fputs("Document exceeds the 1 MiB workspace limit.\n", stderr);
            free(line);
            free(content);
            return;
        }
        if (content_size + (size_t)line_size > content_capacity) {
            size_t next_capacity = content_capacity == 0 ? 4096 : content_capacity * 2;
            char *next;
            while (next_capacity < content_size + (size_t)line_size) {
                next_capacity *= 2;
            }
            next = realloc(content, next_capacity);
            if (next == NULL) {
                perror("edit");
                free(line);
                free(content);
                return;
            }
            content = next;
            content_capacity = next_capacity;
        }
        memcpy(content + content_size, line, (size_t)line_size);
        content_size += (size_t)line_size;
    }
    free(line);
    if (line_size < 0) {
        free(content);
        puts("Edit cancelled.");
        return;
    }
    if (snprintf(temporary, sizeof(temporary), "%s.tmp.XXXXXX", absolute) >= (int)sizeof(temporary)) {
        free(content);
        fputs("Path is too long.\n", stderr);
        return;
    }
    descriptor = mkstemp(temporary);
    if (descriptor < 0) {
        free(content);
        perror("edit");
        return;
    }
    if (fchmod(descriptor, 0600) != 0) {
        perror("edit");
        close(descriptor);
        unlink(temporary);
        free(content);
        return;
    }
    file = fdopen(descriptor, "w");
    if (file == NULL) {
        perror("edit");
        close(descriptor);
        unlink(temporary);
        free(content);
        return;
    }
    if ((content_size > 0 && fwrite(content, 1, content_size, file) != content_size) ||
        fflush(file) != 0 || fsync(descriptor) != 0) {
        perror("edit");
        fclose(file);
        unlink(temporary);
        free(content);
        return;
    }
    if (fclose(file) != 0) {
        perror("edit");
        unlink(temporary);
        free(content);
        return;
    }
    free(content);
    if (rename(temporary, absolute) != 0) {
        perror("edit");
        unlink(temporary);
        return;
    }
    printf("Saved %s/%s\n", CONFIG_ROOT, relative);
}

static void command_touch(const char *argument) {
    char absolute[PATH_MAX];
    char relative[PATH_MAX];
    int descriptor;

    if (argument[0] == '\0') {
        fputs("touch requires a file.\n", stderr);
        return;
    }
    if (!resolve_path(argument, true, absolute, sizeof(absolute), relative, sizeof(relative))) {
        return;
    }
    descriptor = open(absolute, O_WRONLY | O_CREAT | O_NOFOLLOW, 0600);
    if (descriptor < 0) {
        perror("touch");
        return;
    }
    close(descriptor);
}

static void command_mkdir(const char *argument) {
    char absolute[PATH_MAX];
    char relative[PATH_MAX];

    if (argument[0] == '\0') {
        fputs("mkdir requires a directory.\n", stderr);
        return;
    }
    if (!resolve_path(argument, true, absolute, sizeof(absolute), relative, sizeof(relative))) {
        return;
    }
    if (mkdir(absolute, 0700) != 0) {
        perror("mkdir");
    }
}

static void command_remove(const char *argument, bool directory) {
    char absolute[PATH_MAX];
    char relative[PATH_MAX];
    struct stat info;

    if (argument[0] == '\0') {
        fprintf(stderr, "%s requires a path.\n", directory ? "rmdir" : "rm");
        return;
    }
    if (!resolve_path(argument, false, absolute, sizeof(absolute), relative, sizeof(relative))) {
        return;
    }
    if (relative[0] == '\0') {
        fputs("The configuration root cannot be removed.\n", stderr);
        return;
    }
    if (lstat(absolute, &info) != 0) {
        perror(directory ? "rmdir" : "rm");
        return;
    }
    if (directory) {
        if (!S_ISDIR(info.st_mode)) {
            fputs("rmdir only removes directories.\n", stderr);
            return;
        }
        if (strcmp(relative, current_rel) == 0 ||
            (current_rel[0] != '\0' && strncmp(current_rel, relative, strlen(relative)) == 0 &&
             current_rel[strlen(relative)] == '/')) {
            fputs("The current directory or one of its parents cannot be removed.\n", stderr);
            return;
        }
        if (rmdir(absolute) != 0) {
            perror("rmdir");
        }
    } else {
        if (!S_ISREG(info.st_mode)) {
            fputs("rm only removes regular files.\n", stderr);
            return;
        }
        if (unlink(absolute) != 0) {
            perror("rm");
        }
    }
}

static bool verify_jail(void) {
    const char *denied_paths[] = {"/etc/passwd", "/home/pk3s/.ssh", "/home/pk3s/.kube"};
    size_t index;
    int descriptor;
    bool verified_denial = false;

    for (index = 0; index < sizeof(denied_paths) / sizeof(denied_paths[0]); index++) {
        errno = 0;
        descriptor = open(denied_paths[index], O_RDONLY | O_CLOEXEC);
        if (descriptor >= 0) {
            close(descriptor);
            fprintf(stderr, "Filesystem jail allowed forbidden path: %s\n", denied_paths[index]);
            return false;
        }
        if (errno == ENOENT) {
            continue;
        }
        if (errno != EACCES && errno != EPERM) {
            fprintf(stderr, "Filesystem jail did not explicitly deny %s: %s\n",
                    denied_paths[index], strerror(errno));
            return false;
        }
        verified_denial = true;
    }
    if (!verified_denial) {
        fputs("Filesystem jail verification found no existing forbidden path.\n", stderr);
        return false;
    }
    puts("Config workspace filesystem jail verified.");
    return true;
}

int main(int argc, char **argv) {
    char *line = NULL;
    size_t capacity = 0;

    if (getuid() == 0 || geteuid() == 0) {
        fputs("Config workspace refuses to run as root.\n", stderr);
        return 1;
    }
    if (!apply_filesystem_jail()) {
        return 1;
    }
    if (argc == 2 && strcmp(argv[1], "--verify-sandbox") == 0) {
        return verify_jail() ? 0 : 1;
    }
    if (chdir(CONFIG_ROOT) != 0) {
        perror("config workspace");
        return 1;
    }
    umask(0077);
    printf("Productive K3S Config workspace (uid=%ld)\n", (long)geteuid());
    printf("Only %s is available. Type 'help' for commands or 'exit' to return.\n", CONFIG_ROOT);

    while (true) {
        char *command;
        char *argument;
        char *separator;

        printf("config:%s> ", current_rel[0] == '\0' ? "/" : current_rel);
        fflush(stdout);
        if (getline(&line, &capacity, stdin) < 0) {
            putchar('\n');
            break;
        }
        command = trim(line);
        if (command[0] == '\0') {
            continue;
        }
        separator = command;
        while (*separator != '\0' && *separator != ' ' && *separator != '\t') {
            separator++;
        }
        if (*separator == '\0') {
            argument = separator;
        } else {
            *separator = '\0';
            argument = trim(separator + 1);
        }

        if (strcmp(command, "help") == 0) {
            print_help();
        } else if (strcmp(command, "pwd") == 0) {
            command_pwd();
        } else if (strcmp(command, "ls") == 0) {
            command_ls(argument);
        } else if (strcmp(command, "cd") == 0) {
            command_cd(argument);
        } else if (strcmp(command, "view") == 0) {
            command_view(argument);
        } else if (strcmp(command, "edit") == 0) {
            command_edit(argument);
        } else if (strcmp(command, "touch") == 0) {
            command_touch(argument);
        } else if (strcmp(command, "mkdir") == 0) {
            command_mkdir(argument);
        } else if (strcmp(command, "rm") == 0) {
            command_remove(argument, false);
        } else if (strcmp(command, "rmdir") == 0) {
            command_remove(argument, true);
        } else if (strcmp(command, "exit") == 0 || strcmp(command, "quit") == 0) {
            break;
        } else {
            fprintf(stderr, "Unknown command: %s\n", command);
        }
    }

    free(line);
    return 0;
}
