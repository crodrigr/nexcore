import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/**
 * Utilidad simple para generar hashes BCrypt y verificar contraseñas
 * 
 * Uso:
 * 1. Para generar hash de una contraseña:
 *    java PasswordHasher hash "Admin123"
 * 
 * 2. Para verificar una contraseña contra un hash:
 *    java PasswordHasher verify "Admin123" "$2a$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi"
 */
public class PasswordHasher {
    
    public static void main(String[] args) {
        if (args.length == 0) {
            mostrarAyuda();
            return;
        }
        
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(12); // strength = 12
        
        String comando = args[0].toLowerCase();
        
        switch (comando) {
            case "hash":
                if (args.length < 2) {
                    System.err.println("❌ Error: Debes proporcionar una contraseña para generar el hash");
                    System.err.println("Uso: java PasswordHasher hash \"TuContraseña\"");
                    return;
                }
                String password = args[1];
                String hash = encoder.encode(password);
                System.out.println("════════════════════════════════════════════════════════════════");
                System.out.println("✅ HASH GENERADO");
                System.out.println("════════════════════════════════════════════════════════════════");
                System.out.println("Contraseña original: " + password);
                System.out.println("Hash BCrypt (cost=12):");
                System.out.println(hash);
                System.out.println("════════════════════════════════════════════════════════════════");
                break;
                
            case "verify":
                if (args.length < 3) {
                    System.err.println("❌ Error: Debes proporcionar la contraseña y el hash");
                    System.err.println("Uso: java PasswordHasher verify \"TuContraseña\" \"$2a$12$hash...\"");
                    return;
                }
                String passwordToVerify = args[1];
                String hashToCheck = args[2];
                boolean matches = encoder.matches(passwordToVerify, hashToCheck);
                
                System.out.println("════════════════════════════════════════════════════════════════");
                if (matches) {
                    System.out.println("✅ CONTRASEÑA VÁLIDA");
                    System.out.println("════════════════════════════════════════════════════════════════");
                    System.out.println("La contraseña coincide con el hash");
                } else {
                    System.out.println("❌ CONTRASEÑA INVÁLIDA");
                    System.out.println("════════════════════════════════════════════════════════════════");
                    System.out.println("La contraseña NO coincide con el hash");
                }
                System.out.println("Contraseña verificada: " + passwordToVerify);
                System.out.println("Hash: " + hashToCheck);
                System.out.println("════════════════════════════════════════════════════════════════");
                break;
                
            default:
                System.err.println("❌ Comando desconocido: " + comando);
                mostrarAyuda();
        }
    }
    
    private static void mostrarAyuda() {
        System.out.println("════════════════════════════════════════════════════════════════");
        System.out.println("  PASSWORD HASHER - Utilidad BCrypt para NexCore");
        System.out.println("════════════════════════════════════════════════════════════════");
        System.out.println();
        System.out.println("USO:");
        System.out.println("  1. Generar hash de una contraseña:");
        System.out.println("     java PasswordHasher hash \"MiContraseña\"");
        System.out.println();
        System.out.println("  2. Verificar una contraseña contra un hash:");
        System.out.println("     java PasswordHasher verify \"MiContraseña\" \"$2a$12$hash...\"");
        System.out.println();
        System.out.println("EJEMPLOS:");
        System.out.println("  java PasswordHasher hash \"Admin123\"");
        System.out.println("  java PasswordHasher verify \"Admin123\" \"$2a$12$92IXUNpk...\"");
        System.out.println();
        System.out.println("════════════════════════════════════════════════════════════════");
    }
}
