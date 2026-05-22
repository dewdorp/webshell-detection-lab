package lab;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.attribute.PosixFilePermission;
import java.util.EnumSet;
import java.util.Set;

final class UploadPermissions {
    private static final Set<PosixFilePermission> EXECUTABLE_UPLOAD_MODE = EnumSet.of(
        PosixFilePermission.OWNER_READ,
        PosixFilePermission.OWNER_WRITE,
        PosixFilePermission.OWNER_EXECUTE,
        PosixFilePermission.GROUP_READ,
        PosixFilePermission.GROUP_WRITE,
        PosixFilePermission.GROUP_EXECUTE,
        PosixFilePermission.OTHERS_READ,
        PosixFilePermission.OTHERS_EXECUTE
    );

    private UploadPermissions() {}

    static boolean enabled() {
        String value = System.getenv().getOrDefault("LAB_UPLOAD_EXECUTABLE", "0").toLowerCase();
        return value.equals("1") || value.equals("true") || value.equals("yes") || value.equals("on");
    }

    static void prepareDirectory(File directory) throws IOException {
        directory.mkdirs();
        if (enabled()) apply(directory);
    }

    static void prepareFile(File file) throws IOException {
        if (enabled()) apply(file);
    }

    private static void apply(File target) throws IOException {
        try {
            Files.setPosixFilePermissions(target.toPath(), EXECUTABLE_UPLOAD_MODE);
            return;
        } catch (UnsupportedOperationException ignored) {
            // Fall back for non-POSIX filesystems used during local development.
        }

        boolean readable = target.setReadable(true, false);
        boolean writable = target.setWritable(true, false);
        boolean executable = target.setExecutable(true, false);
        if (!readable || !writable || !executable) {
            throw new IOException("failed to apply executable upload permissions to " + target.getAbsolutePath());
        }
    }
}
