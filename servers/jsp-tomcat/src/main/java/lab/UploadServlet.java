package lab;

import java.io.*;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.*;
import javax.servlet.*;
import javax.servlet.http.*;

public class UploadServlet extends HttpServlet {
    private final File serverDir;
    private final File rootDir;
    private final File uploadDir;
    private final File logDir;

    public UploadServlet(File serverDir) {
        this.serverDir = serverDir;
        this.rootDir = serverDir.getParentFile().getParentFile();
        this.uploadDir = new File(serverDir, "uploads");
        this.logDir = new File(serverDir, "logs");
    }

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        uploadDir.mkdirs();
        logDir.mkdirs();
        String path = req.getRequestURI();
        if (path == null || path.isEmpty()) path = "/";
        if ("/".equals(path)) { serveFile(resp, new File(rootDir, "common/templates/index.html"), "text/html; charset=utf-8"); return; }
        if (path.startsWith("/static/")) { String name = cleanFilename(path.substring("/static/".length())); String type = name.endsWith(".css") ? "text/css; charset=utf-8" : "application/javascript; charset=utf-8"; serveFile(resp, new File(rootDir, "common/public/" + name), type); return; }
        if (path.startsWith("/uploads/")) { String name = cleanFilename(URLDecoder.decode(path.substring("/uploads/".length()), StandardCharsets.UTF_8.name())); serveFile(resp, new File(uploadDir, name), "application/octet-stream"); return; }
        if ("/health".equals(path)) { json(resp, 200, "{\"ok\":true,\"runtime\":\"jsp\",\"uploadPath\":\"" + escape(uploadDir.getAbsolutePath()) + "\"}"); return; }
        if ("/upload".equals(path) && "POST".equalsIgnoreCase(req.getMethod())) { handleUpload(req, resp); return; }
        if ("/files".equals(path)) { listFiles(resp); return; }
        json(resp, 404, "{\"success\":false,\"message\":\"not found\"}");
    }

    private void handleUpload(HttpServletRequest req, HttpServletResponse resp) throws IOException, ServletException {
        Part part = req.getPart("file");
        if (part == null || part.getSubmittedFileName() == null) { json(resp, 400, "{\"success\":false,\"message\":\"file field is required\"}"); return; }
        String originalName = part.getSubmittedFileName();
        String storedName = cleanFilename(originalName);
        File storedFile = new File(uploadDir, storedName);
        part.write(storedFile.getAbsolutePath());
        String event = "{"
            + "\"runtime\":\"jsp\"," + "\"originalName\":\"" + escape(originalName) + "\"," + "\"storedName\":\"" + escape(storedName) + "\"," + "\"storedPath\":\"" + escape(storedFile.getAbsolutePath()) + "\"," + "\"size\":" + storedFile.length() + "," + "\"mimeType\":\"" + escape(part.getContentType() == null ? "application/octet-stream" : part.getContentType()) + "\"," + "\"sha256\":\"" + sha256(storedFile) + "\"," + "\"uploadedAt\":\"" + Instant.now().toString() + "\"," + "\"remoteAddress\":\"" + escape(req.getRemoteAddr()) + "\"" + "}";
        Files.write(new File(logDir, "upload-events.jsonl").toPath(), (event + System.lineSeparator()).getBytes(StandardCharsets.UTF_8), java.nio.file.StandardOpenOption.CREATE, java.nio.file.StandardOpenOption.APPEND);
        json(resp, 200, "{\"success\":true,\"file\":" + event + "}");
    }

    private void listFiles(HttpServletResponse resp) throws IOException {
        List<File> files = new ArrayList<>();
        File[] entries = uploadDir.listFiles();
        if (entries != null) for (File entry : entries) if (entry.isFile()) files.add(entry);
        files.sort(Comparator.comparing(File::getName));
        StringBuilder body = new StringBuilder("{\"runtime\":\"jsp\",\"files\":[");
        for (int i = 0; i < files.size(); i++) { File file = files.get(i); if (i > 0) body.append(","); body.append("{").append("\"name\":\"").append(escape(file.getName())).append("\",").append("\"size\":").append(file.length()).append(",").append("\"modifiedAt\":\"").append(Instant.ofEpochMilli(file.lastModified()).toString()).append("\",").append("\"url\":\"/uploads/").append(escape(file.getName())).append("\"").append("}"); }
        body.append("]}");
        json(resp, 200, body.toString());
    }

    private void serveFile(HttpServletResponse resp, File file, String contentType) throws IOException {
        if (!file.isFile()) { resp.setStatus(404); resp.setContentType("text/plain; charset=utf-8"); resp.getWriter().write("Not found"); return; }
        resp.setContentType(contentType);
        try (FileInputStream input = new FileInputStream(file); ServletOutputStream output = resp.getOutputStream()) { input.transferTo(output); }
    }
    private void json(HttpServletResponse resp, int status, String body) throws IOException { resp.setStatus(status); resp.setContentType("application/json; charset=utf-8"); try (PrintWriter writer = resp.getWriter()) { writer.write(body); } }
    private String cleanFilename(String filename) { String name = new File(filename == null || filename.isEmpty() ? "upload.bin" : filename).getName(); name = name.replaceAll("[\\x00-\\x1f]", "_"); return name.isEmpty() ? "upload.bin" : name; }
    private String sha256(File file) throws IOException { try { MessageDigest digest = MessageDigest.getInstance("SHA-256"); byte[] hash = digest.digest(Files.readAllBytes(file.toPath())); StringBuilder hex = new StringBuilder(); for (byte b : hash) hex.append(String.format("%02x", b)); return hex.toString(); } catch (Exception error) { throw new IOException("failed to hash file", error); } }
    private String escape(String value) { if (value == null) return ""; return value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r"); }
}
