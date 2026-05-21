package lab;

import java.io.File;
import javax.servlet.MultipartConfigElement;
import org.apache.catalina.Context;
import org.apache.catalina.Wrapper;
import org.apache.catalina.startup.Tomcat;

public class EmbeddedTomcatServer {
    public static void main(String[] args) throws Exception {
        int port = Integer.parseInt(System.getProperty("lab.port", System.getenv().getOrDefault("LAB_PORT", "8080")));
        File serverDir = new File(".").getCanonicalFile();
        File uploadDir = new File(serverDir, "uploads");
        File logDir = new File(serverDir, "logs");
        uploadDir.mkdirs();
        logDir.mkdirs();
        Tomcat tomcat = new Tomcat();
        tomcat.setPort(port);
        tomcat.getConnector().setProperty("address", "127.0.0.1");
        Context context = tomcat.addContext("", serverDir.getAbsolutePath());
        Wrapper wrapper = Tomcat.addServlet(context, "uploadServlet", new UploadServlet(serverDir));
        wrapper.setMultipartConfigElement(new MultipartConfigElement(uploadDir.getAbsolutePath()));
        context.addServletMappingDecoded("/*", "uploadServlet");
        tomcat.start();
        System.out.printf("JSP/Tomcat lab server listening on http://127.0.0.1:%d%n", port);
        tomcat.getServer().await();
    }
}
