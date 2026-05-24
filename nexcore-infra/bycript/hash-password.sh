#!/bin/bash
# Script para ejecutar PasswordHasher sin tener que compilar manualmente

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAVA_FILE="$SCRIPT_DIR/PasswordHasher.java"

# Buscar el JAR de spring-security-crypto en el proyecto
SECURITY_JAR=$(find ~/Documents/Proyectos/nexcore -name "spring-security-crypto-*.jar" 2>/dev/null | head -1)

if [ -z "$SECURITY_JAR" ]; then
    echo "❌ Error: No se encontró spring-security-crypto JAR"
    echo "Ejecutando desde Spring Boot del auth-service..."
    cd ~/Documents/Proyectos/nexcore/nexcore-auth-service
    
    if [ "$1" == "hash" ] && [ -n "$2" ]; then
        ./gradlew -q run --args="hash $2" 2>/dev/null || {
            # Si no funciona con gradlew, usar jshell inline
            echo "Generando hash con BCrypt..."
            cat > /tmp/hash.java << EOF
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
public class Hash {
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(12);
        String password = "$2";
        String hash = encoder.encode(password);
        System.out.println("════════════════════════════════════════════════════════════════");
        System.out.println("✅ HASH GENERADO");
        System.out.println("════════════════════════════════════════════════════════════════");
        System.out.println("Contraseña: " + password);
        System.out.println("Hash BCrypt:");
        System.out.println(hash);
        System.out.println("════════════════════════════════════════════════════════════════");
    }
}
EOF
            java /tmp/hash.java
        }
    else
        echo ""
        echo "USO SIMPLE:"
        echo "  $0 hash \"TuContraseña\""
        echo ""
        echo "EJEMPLO:"
        echo "  $0 hash \"Admin123\""
        echo ""
    fi
else
    # Compilar y ejecutar con el JAR encontrado
    javac -cp "$SECURITY_JAR" "$JAVA_FILE" 2>/dev/null
    if [ $? -eq 0 ]; then
        java -cp "$SCRIPT_DIR:$SECURITY_JAR" PasswordHasher "$@"
        rm -f "$SCRIPT_DIR/PasswordHasher.class"
    else
        echo "❌ Error al compilar PasswordHasher.java"
    fi
fi
