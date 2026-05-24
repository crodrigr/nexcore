///usr/bin/env jbang "$0" "$@" ; exit $?
//DEPS org.springframework.security:spring-security-crypto:6.2.1
//DEPS org.slf4j:slf4j-simple:2.0.9

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/**
 * Generador simple de hashes BCrypt
 * 
 * USO CON JBANG (instalado):
 *   jbang PasswordHashSimple.java "Admin123"
 * 
 * USO SIN JBANG:
 *   Editar línea 11 y poner tu contraseña, luego ejecutar:
 *   jshell PasswordHashSimple.java
 */
public class PasswordHashSimple {
    
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(12);
        
        if (args.length == 0) {
            System.out.println("════════════════════════════════════════════════════════════════");
            System.out.println("  GENERADOR DE HASH BCRYPT");
            System.out.println("════════════════════════════════════════════════════════════════");
            System.out.println();
            System.out.println("MODO 1 - Con JBang (recomendado):");
            System.out.println("  jbang PasswordHashSimple.java \"TuContraseña\"");
            System.out.println();
            System.out.println("MODO 2 - Editar el código:");
            System.out.println("  1. Modifica la línea donde dice 'String password = ...'");
            System.out.println("  2. Pon tu contraseña entre las comillas");
            System.out.println("  3. Ejecuta: jbang PasswordHashSimple.java");
            System.out.println();
            System.out.println("MODO 3 - Desde auth-service:");
            System.out.println("  cd nexcore-auth-service");
            System.out.println("  ./gradlew bootRun");
            System.out.println("  Luego usa la API REST /auth/utils/hash?password=Admin123");
            System.out.println();
            System.out.println("════════════════════════════════════════════════════════════════");
            
            // Por defecto genera hash de "Admin123" si no se pasan argumentos
            String defaultPassword = "Admin123";
            System.out.println("\n⚠️  Generando hash por defecto para: " + defaultPassword);
            System.out.println();
            generarHash(encoder, defaultPassword);
            return;
        }
        
        // Hash de la contraseña proporcionada
        String password = args[0];
        generarHash(encoder, password);
    }
    
    private static void generarHash(BCryptPasswordEncoder encoder, String password) {
        String hash = encoder.encode(password);
        System.out.println("════════════════════════════════════════════════════════════════");
        System.out.println("✅ HASH BCrypt GENERADO (cost=12)");
        System.out.println("════════════════════════════════════════════════════════════════");
        System.out.println("Contraseña:  " + password);
        System.out.println();
        System.out.println("Hash:");
        System.out.println(hash);
        System.out.println();
        System.out.println("Copia este hash para tus scripts SQL");
        System.out.println("════════════════════════════════════════════════════════════════");
    }
}
