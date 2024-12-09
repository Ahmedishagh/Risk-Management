// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GestionnaireRisque {
    struct Contrepartie {
        address portefeuille;
        uint256 scoreCredit;
        uint256 limiteExposition;
        uint256 expositionTotale;
        bool estActif;
    }

    mapping(address => Contrepartie) public contreparties;
    mapping(address => mapping(address => uint256)) public expositions;

    event ContrepartieAjoutee(address indexed portefeuille, uint256 limiteExposition);
    event ExpositionMiseAJour(address indexed contrepartie, uint256 nouvelleExposition);
    event LimiteDepassee(address indexed contrepartie, uint256 exposition, uint256 limite);

    modifier seulementActif(address portefeuille) {
        require(contreparties[portefeuille].estActif, "La contrepartie n'est pas active.");
        _;
    }

    function ajouterContrepartie(
        address portefeuille,
        uint256 scoreCredit,
        uint256 limiteExposition
    ) public {
        require(portefeuille != address(0), "Adresse invalide.");
        require(limiteExposition > 0, "La limite d'exposition doit etre positive.");
        require(scoreCredit <= 100, "Score de credit invalide."); // Nouveau contrôle
        require(!contreparties[portefeuille].estActif, "Contrepartie deja existante.");

        contreparties[portefeuille] = Contrepartie(
            portefeuille,
            scoreCredit,
            limiteExposition,
            0,
            true
        );

        emit ContrepartieAjoutee(portefeuille, limiteExposition);
    }

    function mettreAJourExposition(
        address contrepartie1,
        address contrepartie2,
        uint256 montant
    ) public seulementActif(contrepartie1) seulementActif(contrepartie2) {
        require(contrepartie1 != contrepartie2, "Les adresses doivent etre differentes.");
        require(montant > 0, "Le montant doit etre positif.");

        expositions[contrepartie1][contrepartie2] += montant;
        contreparties[contrepartie1].expositionTotale += montant;

        emit ExpositionMiseAJour(contrepartie1, contreparties[contrepartie1].expositionTotale);

        if (contreparties[contrepartie1].expositionTotale > contreparties[contrepartie1].limiteExposition) {
            emit LimiteDepassee(
                contrepartie1,
                contreparties[contrepartie1].expositionTotale,
                contreparties[contrepartie1].limiteExposition
            );
        }
    }

    function calculerRisque(address portefeuille) public view seulementActif(portefeuille) returns (uint256) {
        uint256 exposition = contreparties[portefeuille].expositionTotale;
        uint256 limite = contreparties[portefeuille].limiteExposition;
        require(limite > 0, "La limite doit etre positive."); // Ajout

        return (exposition * 100) / limite;
    }

    function desactiverContrepartie(address portefeuille) public seulementActif(portefeuille) {
        contreparties[portefeuille].estActif = false;
    }

    function obtenirDetailsContrepartie(address portefeuille)
        public
        view
        returns (
            uint256 scoreCredit,
            uint256 limiteExposition,
            uint256 expositionTotale,
            bool estActif
        )
    {
        Contrepartie memory c = contreparties[portefeuille];
        return (c.scoreCredit, c.limiteExposition, c.expositionTotale, c.estActif);
    }
}