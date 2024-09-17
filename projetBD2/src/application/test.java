package application;

import java.sql.SQLException;

public class test {
    public static void main(String[] args) {
        AppCentrale centrale = new AppCentrale();
        // AppEtudiant etudiant1 = new AppEtudiant("younes.benbouchta@student.vinci.be", "a");
        // etudiant1.visualiserCoursEtudiant();
        centrale.visualiserTousLesProjets();
    }
}
