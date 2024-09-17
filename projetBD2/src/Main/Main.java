package Main;

import application.AppCentrale;
import application.AppEtudiant;

import java.sql.SQLException;
import java.util.Scanner;

public class Main {
    private static final Scanner scanner = new Scanner(System.in);
    public static void main(String[] args) throws SQLException {
        int choix = 0;
        do{
            System.out.println("1) Application Centrale");
            System.out.println("2) Application Etudiante");

            System.out.println();
            System.out.print("Entrez votre choix : ");
            choix = scanner.nextInt();
            switch(choix){
                case 1:
                    AppCentrale appCentrale = new AppCentrale();
                    break;
                case 2:
                    System.out.print("Veuillez entrer votre email : ");
                    String email = scanner.next();
                    System.out.println();
                    System.out.print("Veuillez entrer votre mot de passe : ");
                    String mdp = scanner.next();
                    AppEtudiant appEtudiant = new AppEtudiant(email, mdp);
                    appEtudiant.choix();
                    break;
                default:
                    System.out.println("Le choix est invalide.");
                    break;
            }
        }while (choix > 0 && choix < 3);
    }
}
