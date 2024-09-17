package application;

import BCrypt.BCrypt;

import java.sql.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Scanner;

public class AppCentrale {
    private static final Scanner scanner = new Scanner(System.in);
    private Connection conn;
    public AppCentrale(){
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }
        String url="jdbc:postgresql://localhost:5432/postgres";
        this.conn=null;
        try {
            this.conn= DriverManager.getConnection(url,"postgres","younes2002");
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }
    }

    public static void main(String[] args){
        AppCentrale appCentrale = new AppCentrale();
        appCentrale.choix();
    }

    public void choix() {
        int choix;
        System.out.println("Application Centrale");
        do {
            System.out.println("\nVeuillez faire votre choix : ");
            System.out.println("1 --> Ajouter un cours");
            System.out.println("2 --> Ajouter un étudiant");
            System.out.println("3 --> Inscrire un étudiant à un cours");
            System.out.println("4 --> Créer un projet");
            System.out.println("5 --> Créer un groupe");
            System.out.println("6 --> Visualiser tous les cours");
            System.out.println("7 --> Visualiser tous les projets");
            System.out.println("8 --> Visualiser la compositions des groupes d'un projet");
            System.out.println("9 --> Valider un groupe");
            System.out.println("10 --> Valider tous les groupes d'un projet");
            System.out.println("0 --> Arrêter le programme");
            System.out.print("\nVotre choix : ");
            choix = Integer.parseInt(scanner.nextLine());
            switch (choix) {
                case 0 : System.out.println("Fin du programme."); break;
                case 1 : ajouterCours(); break;
                case 2 : ajouterEtudiant(); break;
                case 3 : inscrireEtudiantAuCours(); break;
                case 4 : creerProjet(); break;
                case 5 : creerGroupe(); break;
                case 6 : visualiserTousLesCours(); break;
                case 7 : visualiserTousLesProjets(); break;
                case 8 : visualiserCompositionsDeGroupeDUnProjet(); break;
                case 9 : validerGroupe(); break;
                case 10 : validerTousLesGroupes();break;
                default : System.out.println("Ce choix est invalide."); break;
            }
        } while (choix != 0);
        try {
            conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public void ajouterCours() {
        try {
            PreparedStatement ps = conn.prepareStatement("SELECT projet.ajouter_cours(?, ?, ?, ?)");
            System.out.print("Entrez le code du cours: ");
            String codeCours = scanner.nextLine();
            System.out.print("Entrez le nom du cours: ");
            String nom = scanner.nextLine();
            System.out.print("Entrez le bloc auquel le cours est assigné: ");
            int bloc = Integer.parseInt(scanner.nextLine());
            System.out.print("Entrez le nombre de crédits du cours: ");
            int nbCredits = Integer.parseInt(scanner.nextLine());
            ps.setString(1, codeCours);
            ps.setString(2, nom);
            ps.setInt(3, bloc);
            ps.setInt(4, nbCredits);
            ps.execute();
            System.out.println("Le cours a été ajouté avec succès");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public void ajouterEtudiant() {
        try {
            PreparedStatement ps = conn.prepareStatement("SELECT projet.ajouter_etudiant(?, ?, ?, ?)");
            System.out.print("Entrez le nom de l'étudiant: ");
            String nom = scanner.nextLine();
            System.out.print("Entrez le prénom de l'étudiant: ");
            String prenom = scanner.nextLine();
            System.out.print("Entrez l'email de l'étudiant: ");
            String email = scanner.nextLine();
            System.out.print("Entrez le mot de passe de l'étudiant: ");
            String motDePasse = scanner.nextLine();
            String sel = BCrypt.gensalt();
            String mdpAStockerDB = BCrypt.hashpw(motDePasse, sel);
            ps.setString(1, nom);
            ps.setString(2, prenom);
            ps.setString(3, email);
            ps.setString(4, mdpAStockerDB);
            ps.execute();

            System.out.println("L'étudiant a été ajouté avec succès.");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public void inscrireEtudiantAuCours() {
        try {
            PreparedStatement ps = conn.prepareStatement("SELECT projet.inscrire_etudiant_au_cours(?, ?)");
            System.out.print("Entrez l'adresse email de l'étudiant: ");
            String adresseEmail = scanner.nextLine();
            System.out.print("Entrez le code du cours: ");
            String codeCours = scanner.nextLine();
            ps.setString(1, adresseEmail);
            ps.setString(2, codeCours);
            ps.execute();

            System.out.println("L'étudiant a été inscrit au cours avec succès");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public void creerProjet() {
        try {
            PreparedStatement ps = conn.prepareStatement("SELECT projet.creer_projet(?, ?, ?, ?, ?)");
            System.out.print("Entrez l'identifiant du projet: ");
            String idProjet = scanner.nextLine();
            System.out.print("Entrez le nom du projet: ");
            String nom = scanner.nextLine();
            System.out.print("Entrez le code du cours: ");
            String codeCours = scanner.nextLine();
            System.out.print("Entrez la date de début (format: AAAA-MM-JJ:): ");
            String dateDebut = scanner.nextLine();
            System.out.print("Entrez la date de fin (format: AAAA-MM-JJ): ");
            String dateFin = scanner.nextLine();
            ps.setString(1, idProjet);
            ps.setString(2, nom);
            ps.setString(3, codeCours);
            ps.setDate(4, Date.valueOf(dateDebut));
            ps.setDate(5, Date.valueOf(dateFin));
            ps.execute();

            System.out.println("Le projet a été créé avec succès");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public void creerGroupe(){
        try{
            PreparedStatement ps = conn.prepareStatement("SELECT projet.creer_groupe(?, ?, ?)");
            System.out.print("Entrez l'id du projet à assigner au groupe : ");
            String idProjet = scanner.nextLine();
            System.out.print("Entrez le nombre de groupe a créer : ");
            int nbrGroupeACreer  = Integer.parseInt(scanner.nextLine());
            System.out.print("Entrez le nombre de places à créer : ");
            int nbrPlacesACreer = Integer.parseInt(scanner.nextLine());
            ps.setString(1, idProjet);
            ps.setInt(2, nbrGroupeACreer);
            ps.setInt(3, nbrPlacesACreer);
            ps.execute();
            System.out.println("Le groupe a été créer avec succès.");
        }catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public void visualiserTousLesCours(){
        try{
            PreparedStatement ps = conn.prepareStatement("SELECT * FROM projet.visualiser_cours");
            ResultSet resultSet = ps.executeQuery();

            while (resultSet.next()){
                System.out.println("\nCode du cours : " + resultSet.getString(1));
                System.out.println("Nom du cours : " + resultSet.getString(2));
                System.out.println("Liste des identifiants des projets : " + resultSet.getString(3));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public void visualiserTousLesProjets() {
        try {
            PreparedStatement ps = conn.prepareStatement("SELECT * FROM projet.visualiser_projets");
            ResultSet resultSet = ps.executeQuery();

            while (resultSet.next()) {
                System.out.println("\nIdentifiant: " + resultSet.getString(1));
                System.out.println("Nom: " + resultSet.getString(2));
                System.out.println("Code du cours: " + resultSet.getString(3));
                System.out.println("Nombre de groupes: " + resultSet.getString(4));
                System.out.println("Nombre de groupes complets: " + resultSet.getString(5));
                System.out.println("Nombre de groupes validés: " + resultSet.getString(6));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }


    public void visualiserCompositionsDeGroupeDUnProjet(){
        try{
            PreparedStatement ps = conn.prepareStatement("SELECT * FROM projet.visualiser_composition_groupes(?)");
            System.out.print("Veuillez entrer l'identifiant du projet : ");
            String idProjet = scanner.nextLine();
            ps.setString(1, idProjet);
            ResultSet resultSet = ps.executeQuery();
            while (resultSet.next()){
                System.out.println("\nNuméro de groupe : " + resultSet.getInt(1));
                System.out.println("Nom : " + resultSet.getString(2));
                System.out.println("Prenom : " + resultSet.getString(3));
                System.out.println("Groupe complet ? : " + (resultSet.getString(4).equals("f") ? "non" : "oui"));
                System.out.println("Groupe valide ? : " + (resultSet.getString(5).equals("f") ? "non" : "oui"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public void validerGroupe() {
        try {
            PreparedStatement ps = conn.prepareStatement("SELECT projet.valider_groupe(?, ?)");
            System.out.print("Entrez l'identifiant du projet: ");
            String idProjet = scanner.nextLine();
            System.out.print("Entrez le numéro du groupe: ");
            int numeroGroupe = Integer.parseInt(scanner.nextLine());
            ps.setString(1, idProjet);
            ps.setInt(2, numeroGroupe);
            ps.execute();

            System.out.println("Le groupe a été validé avec succès");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
    public void validerTousLesGroupes(){
        try{
            PreparedStatement ps = conn.prepareStatement("SELECT projet.valider_tous_groupes(?)");
            System.out.print("Veuillez entrez l'identifiant du projet : ");
            String idProjet = scanner.nextLine();
            ps.setString(1, idProjet);
            ps.execute();

            System.out.println("Les groupes ont été validé avec succès.");
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

}