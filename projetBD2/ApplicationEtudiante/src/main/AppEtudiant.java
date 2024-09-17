package main;

import services.BCrypt;

import java.sql.*;
import java.util.Scanner;

public class AppEtudiant {
    private Connection conn;
    private static final Scanner scanner = new Scanner(System.in);
    private int idEtudiant;
    public AppEtudiant() {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }
        String url="jdbc:postgresql://172.24.2.6:5432/dbyounesbenbouchta";
        this.conn=null;
        try {
            this.conn= DriverManager.getConnection(url,"quocduong","JQT9ELSA3");
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }
    }
    public void choix(){
        int choix;
        System.out.println("\nApplication Etudiante\n");
        if (connexionEtudiant()){
            do {
                System.out.println("\nVeuillez faire votre choix : ");
                System.out.println("1 --> Visualiser tous vos cours");
                System.out.println("2 --> S'ajouter dans un groupe");
                System.out.println("3 --> Se retirer d'un groupe");
                System.out.println("4 --> Visualiser tous vos projets");
                System.out.println("5 --> Visualiser tous vos projets auxquels vous n'avez pas encore de groupe");
                System.out.println("6 --> Visualiser toutes les compositions de groupes incomplets d'un projet");
                System.out.println("0 --> Arrêter le programme");
                System.out.print("\nVotre choix: ");
                choix = Integer.parseInt(scanner.nextLine());
                switch (choix) {
                    case 0 : System.out.println("Fin du programme."); break;
                    case 1 : visualiserCoursEtudiant(); break;
                    case 2 : ajouterEtudiantDuGroupe(); break;
                    case 3 : retirerEtudiantDuGroupe(); break;
                    case 4 : visualiserProjetsEtudiant(); break;
                    case 5 : visualiserProjetsEtudiantSansGroupe(); break;
                    case 6 : visualiserCompositionGroupesIncomplets(); break;
                    default : System.out.println("Ce choix est invalide."); break;
                }
            } while (choix != 0);
            try {
                conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
    public boolean connexionEtudiant(){
        System.out.print("Veuillez entrer votre email : ");
        String email = scanner.nextLine();
        System.out.print("Veuillez entrer votre mot de passe : ");
        String motDePasse = scanner.nextLine();
        try{
            String dbMdp = "";
            int idEtudiant = 0;
            PreparedStatement ps1 = conn.prepareStatement("SELECT mot_de_passe, id_etudiant FROM projet.etudiants WHERE email = ?");
            ps1.setString(1, email);
            ResultSet resultSet = ps1.executeQuery();
            while (resultSet.next()){
                dbMdp = resultSet.getString(1);
                idEtudiant = resultSet.getInt(2);
            };
            if (BCrypt.checkpw(motDePasse, dbMdp)){
                this.idEtudiant = idEtudiant;
            }
            else{
                System.out.println("Le mot de passe est incorrect.");
                conn.close();
                return false;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return true;
    }
    public void visualiserCoursEtudiant(){
        try{
            PreparedStatement ps = this.conn.prepareStatement("SELECT * FROM projet.visualiser_cours_etudiant WHERE id_etudiant = ?");
            ps.setInt(1, this.idEtudiant);
            ResultSet resultSet = ps.executeQuery();
            while (resultSet.next()){
                System.out.println("\nCode du cours : " + resultSet.getString(2));
                System.out.println("Nom du cours : " + resultSet.getString(3));
                System.out.println("IDs des projets du cours : "  + resultSet.getString(4));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public void ajouterEtudiantDuGroupe(){
        try{
            PreparedStatement ps = this.conn.prepareStatement("SELECT projet.rajouter_etudiant_groupe(?, ?, ?)");
            System.out.print("Entrez l'ID du projet: ");
            String idProjet = scanner.nextLine();
            System.out.print("Entrez le numéro du groupe: ");
            int numGroupe = Integer.parseInt(scanner.nextLine());
            ps.setInt(1, this.idEtudiant);
            ps.setString(2, idProjet);
            ps.setInt(3, numGroupe);
            ps.execute();
            System.out.println("\nL'étudiant a été ajouté avec succès.");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public void retirerEtudiantDuGroupe(){
        try{
            PreparedStatement ps = this.conn.prepareStatement("SELECT projet.retirer_etudiant_du_groupe(?, ?)");
            System.out.print("Entrez l'ID du projet: ");
            String idProjet = scanner.nextLine();
            ps.setInt(1, this.idEtudiant);
            ps.setString(2, idProjet);
            ps.execute();
            System.out.println("\nL'étudiant a été retiré avec succès.");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public void visualiserProjetsEtudiant(){
        try{
            PreparedStatement ps = this.conn.prepareStatement("SELECT * FROM projet.visualiser_projets_etudiant WHERE id_etudiant = ?");
            ps.setInt(1, this.idEtudiant);
            ResultSet resultSet = ps.executeQuery();
            while (resultSet.next()){
                System.out.println("\nID du projet: " + resultSet.getString(1));
                System.out.println("Nom : " + resultSet.getString(2));
                System.out.println("Code du cours : " + resultSet.getString(3));
                System.out.println("Numéro du groupe : "  + resultSet.getString(4));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public void visualiserProjetsEtudiantSansGroupe(){
        try{
            PreparedStatement ps = conn.prepareStatement("SELECT * FROM projet.visualiser_projets_etudiant_sans_groupe WHERE id_etudiant = ?");
            ps.setInt(1, this.idEtudiant);
            ResultSet resultSet = ps.executeQuery();
            while (resultSet.next()){
                System.out.println("\nID du projet: " + resultSet.getString(1));
                System.out.println("Nom du projet: " + resultSet.getString(2));
                System.out.println("Code du cours : " + resultSet.getString(3));
                System.out.println("Date de début : "  + resultSet.getString(4));
                System.out.println("Date de fin : " + resultSet.getString(5));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public void visualiserCompositionGroupesIncomplets(){
        try{
            PreparedStatement ps = conn.prepareStatement("SELECT * FROM projet.visualiser_composition_groupes_incomplets(?) ");
            System.out.print("Veuillez entrer l'identifiant du projet : ");
            String idProjet = scanner.nextLine();
            ps.setString(1, idProjet);
            ResultSet resultSet = ps.executeQuery();
            while (resultSet.next()){
                System.out.println("\nNuméro de groupe : " + resultSet.getInt(1));
                System.out.println("Nom : " + resultSet.getString(2));
                System.out.println("Prénom : " + resultSet.getString(3));
                System.out.println("Nombres de places : " + resultSet.getString(4));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {

        AppEtudiant appEtudiant = new AppEtudiant();
        appEtudiant.choix();
    }
}
