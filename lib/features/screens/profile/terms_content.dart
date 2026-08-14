/// Contenu des Conditions Générales d'Utilisation.
///
/// Séparé de l'écran pour qu'un juriste puisse le relire et le
/// modifier sans toucher au code d'affichage.
///
/// ⚠️ Ce texte est une base sérieuse mais NON VALIDÉE par un avocat.
/// Les références aux lois guinéennes et les mentions légales de
/// l'entreprise doivent être vérifiées avant publication.
library;

sealed class TermsBloc {
  const TermsBloc();
}

/// Un paragraphe de texte courant
class Paragraphe extends TermsBloc {
  const Paragraphe(this.texte);
  final String texte;
}

/// Une liste à puces
class Puces extends TermsBloc {
  const Puces(this.items);
  final List<String> items;
}

/// Un encadré d'avertissement (clause importante)
class Encadre extends TermsBloc {
  const Encadre(this.texte);
  final String texte;
}

class TermsSection {
  const TermsSection({
    required this.numero,
    required this.titre,
    required this.blocs,
  });

  final String numero;
  final String titre;
  final List<TermsBloc> blocs;
}

// ─────────────────────────────────────────────────────────────
// Mentions à compléter avant publication
// ─────────────────────────────────────────────────────────────
const kEditeur      = '[RAISON SOCIALE]';
const kFormeSociale = '[FORME JURIDIQUE — SARL, SA…]';
const kSiege        = '[ADRESSE DU SIÈGE], Conakry, République de Guinée';
const kRccm         = '[NUMÉRO RCCM]';
const kNif          = '[NUMÉRO NIF]';
const kEmail        = '[EMAIL DE CONTACT]';
const kTelephone    = '[TÉLÉPHONE]';

const kDerniereMaj  = '14 août 2026';
const kVersionCgu   = '1.0';

/// Les points essentiels, affichés en tête pour que l'utilisateur
/// saisisse l'important sans tout lire.
const kResume = <String>[
  'YAA met en relation des clients, des établissements et des '
      'coursiers indépendants. YAA ne vend pas les produits et '
      'n\'effectue pas lui-même les livraisons.',
  'Vous devez avoir 18 ans ou plus et fournir des informations exactes.',
  'Certains objets sont strictement interdits à l\'expédition.',
  'Vos données de localisation sont utilisées uniquement pour la '
      'prestation, conformément à la loi guinéenne.',
  'Le droit guinéen s\'applique ; les litiges relèvent des '
      'juridictions de Conakry.',
];

const kSections = <TermsSection>[
  // ── 1 ────────────────────────────────────────────────────
  TermsSection(
    numero: '1',
    titre: 'Objet et acceptation',
    blocs: [
      Paragraphe(
        'Les présentes Conditions Générales d\'Utilisation (ci-après '
        '« CGU ») régissent l\'accès et l\'utilisation de l\'application '
        'mobile YAA (ci-après « l\'Application »), éditée par $kEditeur, '
        '$kFormeSociale au capital social déclaré, dont le siège est '
        'situé $kSiege, immatriculée au Registre du Commerce et du '
        'Crédit Mobilier sous le numéro $kRccm.',
      ),
      Paragraphe(
        'La création d\'un compte et l\'utilisation de l\'Application '
        'emportent acceptation pleine, entière et sans réserve des '
        'présentes CGU. L\'Utilisateur qui n\'accepte pas ces conditions '
        'doit renoncer à utiliser l\'Application.',
      ),
      Paragraphe(
        'Les présentes CGU sont conclues conformément à la '
        'réglementation guinéenne applicable aux transactions '
        'électroniques et au commerce électronique.',
      ),
    ],
  ),

  // ── 2 ────────────────────────────────────────────────────
  TermsSection(
    numero: '2',
    titre: 'Définitions',
    blocs: [
      Puces([
        '« Utilisateur » : toute personne physique majeure disposant '
            'd\'un compte sur l\'Application.',
        '« Établissement » : commerçant partenaire (restaurant, '
            'pharmacie, boutique, supermarché) proposant ses produits '
            'via l\'Application.',
        '« Coursier » : prestataire indépendant assurant le transport '
            'de biens ou de personnes.',
        '« Service de Livraison » : acheminement d\'un colis d\'un '
            'point de départ vers un point d\'arrivée.',
        '« Service de Course » : transport d\'une personne d\'un point '
            'de départ vers un point d\'arrivée.',
        '« Commande » : achat de produits auprès d\'un Établissement, '
            'avec livraison ou retrait sur place.',
      ]),
    ],
  ),

  // ── 3 ────────────────────────────────────────────────────
  TermsSection(
    numero: '3',
    titre: 'Nature du service — rôle d\'intermédiaire',
    blocs: [
      Encadre(
        'YAA agit exclusivement en qualité d\'intermédiaire technique '
        'de mise en relation. YAA n\'est ni vendeur des produits '
        'proposés, ni transporteur, ni employeur des Coursiers.',
      ),
      Paragraphe(
        'Le contrat de vente se forme directement entre l\'Utilisateur '
        'et l\'Établissement. Le contrat de transport se forme '
        'directement entre l\'Utilisateur et le Coursier, lequel '
        'exerce en qualité de prestataire indépendant.',
      ),
      Paragraphe(
        'En conséquence, la qualité, la conformité, la quantité et la '
        'sécurité sanitaire des produits relèvent de la responsabilité '
        'exclusive de l\'Établissement. L\'exécution matérielle du '
        'transport relève de celle du Coursier.',
      ),
    ],
  ),

  // ── 4 ────────────────────────────────────────────────────
  TermsSection(
    numero: '4',
    titre: 'Inscription et compte utilisateur',
    blocs: [
      Paragraphe(
        'L\'inscription requiert des informations exactes, complètes '
        'et tenues à jour : nom, prénom, numéro de téléphone valide et '
        'adresse électronique. L\'Utilisateur garantit la véracité des '
        'informations communiquées.',
      ),
      Paragraphe(
        'L\'accès aux Services est réservé aux personnes physiques '
        'âgées de dix-huit (18) ans révolus et juridiquement capables.',
      ),
      Paragraphe(
        'L\'Utilisateur est seul responsable de la confidentialité de '
        'ses identifiants et de toute activité effectuée depuis son '
        'compte. Toute utilisation frauduleuse doit être signalée sans '
        'délai à $kEmail.',
      ),
    ],
  ),

  // ── 5 ────────────────────────────────────────────────────
  TermsSection(
    numero: '5',
    titre: 'Objets et usages interdits',
    blocs: [
      Paragraphe(
        'Il est formellement interdit de confier au transport, via '
        'l\'Application, les biens suivants :',
      ),
      Puces([
        'Stupéfiants, substances psychotropes et produits prohibés par '
            'la législation guinéenne.',
        'Armes, munitions, explosifs, matières inflammables, '
            'corrosives, toxiques ou radioactives.',
        'Espèces, métaux précieux, pierres précieuses et titres au '
            'porteur.',
        'Médicaments soumis à prescription, hors circuit '
            'pharmaceutique autorisé.',
        'Espèces animales ou végétales protégées, restes humains.',
        'Contrefaçons et biens issus d\'une infraction.',
        'Tout bien dont la circulation est soumise à autorisation '
            'administrative non détenue par l\'expéditeur.',
      ]),
      Encadre(
        'L\'Utilisateur est seul responsable du contenu des colis '
        'qu\'il expédie et garantit YAA contre toute conséquence, '
        'notamment pénale, résultant d\'une expédition prohibée.',
      ),
    ],
  ),

  // ── 6 ────────────────────────────────────────────────────
  TermsSection(
    numero: '6',
    titre: 'Prix, paiement et facturation',
    blocs: [
      Paragraphe(
        'Les prix sont indiqués en Francs Guinéens (GNF), toutes '
        'taxes comprises. Le montant des frais de livraison est '
        'communiqué avant validation de la demande, sur la base de la '
        'distance estimée et du véhicule retenu.',
      ),
      Paragraphe(
        'Le paiement s\'effectue par les moyens proposés dans '
        'l\'Application, notamment les services de paiement mobile. '
        'YAA n\'a pas accès aux données bancaires de l\'Utilisateur, '
        'lesquelles transitent directement par le prestataire de '
        'paiement concerné.',
      ),
      Paragraphe(
        'Une estimation tarifaire ne constitue pas un prix ferme '
        'lorsque l\'itinéraire réellement emprunté diffère '
        'sensiblement de l\'itinéraire prévu.',
      ),
    ],
  ),

  // ── 7 ────────────────────────────────────────────────────
  TermsSection(
    numero: '7',
    titre: 'Annulation et remboursement',
    blocs: [
      Paragraphe(
        'L\'Utilisateur peut annuler une demande tant qu\'aucun '
        'Coursier n\'a été assigné. Passé ce stade, une participation '
        'aux frais engagés peut être retenue.',
      ),
      Paragraphe(
        'Toute réclamation doit être adressée à $kEmail dans un délai '
        'de quarante-huit (48) heures suivant la prestation, '
        'accompagnée des justificatifs utiles.',
      ),
    ],
  ),

  // ── 8 ────────────────────────────────────────────────────
  TermsSection(
    numero: '8',
    titre: 'Obligations de l\'Utilisateur',
    blocs: [
      Puces([
        'Utiliser l\'Application conformément aux lois et règlements '
            'en vigueur en République de Guinée.',
        'Fournir une adresse exacte et demeurer joignable au numéro '
            'communiqué pendant la prestation.',
        'Adopter un comportement respectueux envers les Coursiers et '
            'le personnel des Établissements.',
        'Ne pas tenter d\'accéder frauduleusement au système, de le '
            'perturber, ni d\'en extraire massivement les données.',
        'Ne pas usurper l\'identité d\'un tiers.',
      ]),
      Paragraphe(
        'Tout manquement peut entraîner la suspension immédiate du '
        'compte, sans préjudice des poursuites, notamment sur le '
        'fondement de la législation guinéenne relative à la '
        'cybersécurité.',
      ),
    ],
  ),

  // ── 9 ────────────────────────────────────────────────────
  TermsSection(
    numero: '9',
    titre: 'Responsabilité',
    blocs: [
      Paragraphe(
        'YAA est tenu d\'une obligation de moyens portant sur le bon '
        'fonctionnement de la plateforme de mise en relation.',
      ),
      Paragraphe('La responsabilité de YAA ne saurait être engagée :'),
      Puces([
        'Pour la qualité, la conformité ou les vices des produits '
            'fournis par les Établissements.',
        'Pour les fautes, retards ou dommages imputables à un '
            'Coursier dans l\'exécution du transport.',
        'Pour les informations erronées communiquées par '
            'l\'Utilisateur, notamment une adresse inexacte.',
        'Pour les interruptions de service dues au réseau, à la '
            'couverture mobile, à l\'électricité ou aux services tiers '
            '(cartographie, paiement).',
        'Pour les dommages indirects, tels qu\'une perte '
            'd\'exploitation, de chiffre d\'affaires ou de chance.',
      ]),
      Encadre(
        'En toute hypothèse, si la responsabilité de YAA venait à être '
        'retenue, celle-ci serait limitée au montant effectivement '
        'payé par l\'Utilisateur au titre de la prestation concernée.',
      ),
    ],
  ),

  // ── 10 ───────────────────────────────────────────────────
  TermsSection(
    numero: '10',
    titre: 'Données personnelles',
    blocs: [
      Paragraphe(
        'Les données collectées sont traitées conformément à la '
        'législation guinéenne relative à la cybersécurité et à la '
        'protection des données à caractère personnel.',
      ),
      Paragraphe(
        'Sont collectées les données strictement nécessaires : '
        'identité, coordonnées, adresses de livraison, historique des '
        'commandes et données de localisation.',
      ),
      Paragraphe(
        'Ces données ne sont transmises qu\'aux parties nécessaires à '
        'l\'exécution de la prestation — Établissement concerné, '
        'Coursier assigné, prestataire de paiement — et ne font '
        'l\'objet d\'aucune cession commerciale à des tiers.',
      ),
      Paragraphe(
        'L\'Utilisateur dispose d\'un droit d\'accès, de '
        'rectification, d\'opposition et de suppression de ses '
        'données, exerçable à l\'adresse $kEmail. La suppression du '
        'compte n\'affecte pas la conservation des données requises '
        'par les obligations comptables et fiscales.',
      ),
    ],
  ),

  // ── 11 ───────────────────────────────────────────────────
  TermsSection(
    numero: '11',
    titre: 'Géolocalisation',
    blocs: [
      Paragraphe(
        'L\'Application accède à la position de l\'appareil afin de '
        'proposer les établissements proches, calculer les itinéraires '
        'et permettre le suivi des prestations en cours.',
      ),
      Paragraphe(
        'Cet accès requiert le consentement exprès de l\'Utilisateur, '
        'révocable à tout moment depuis les réglages du système '
        'd\'exploitation. Sa révocation peut rendre certaines '
        'fonctionnalités inopérantes.',
      ),
    ],
  ),

  // ── 12 ───────────────────────────────────────────────────
  TermsSection(
    numero: '12',
    titre: 'Notations et contenus publiés',
    blocs: [
      Paragraphe(
        'L\'Utilisateur peut évaluer les prestations. Les avis doivent '
        'être sincères, mesurés et exempts de propos injurieux, '
        'diffamatoires ou discriminatoires.',
      ),
      Paragraphe(
        'YAA se réserve le droit de retirer tout contenu manifestement '
        'illicite ou contraire aux présentes CGU.',
      ),
    ],
  ),

  // ── 13 ───────────────────────────────────────────────────
  TermsSection(
    numero: '13',
    titre: 'Propriété intellectuelle',
    blocs: [
      Paragraphe(
        'La marque YAA, les logos, l\'interface, les textes et les '
        'développements informatiques demeurent la propriété exclusive '
        'de $kEditeur.',
      ),
      Paragraphe(
        'Toute reproduction, représentation, extraction ou '
        'réutilisation, totale ou partielle, sans autorisation écrite '
        'préalable est interdite et constitue une contrefaçon.',
      ),
    ],
  ),

  // ── 14 ───────────────────────────────────────────────────
  TermsSection(
    numero: '14',
    titre: 'Suspension et résiliation',
    blocs: [
      Paragraphe(
        'YAA peut suspendre ou fermer un compte, sans indemnité, en '
        'cas de manquement aux présentes CGU, de comportement '
        'frauduleux, d\'impayé ou d\'atteinte à la sécurité des '
        'personnes.',
      ),
      Paragraphe(
        'L\'Utilisateur peut demander la suppression de son compte à '
        'tout moment depuis l\'Application ou à l\'adresse $kEmail.',
      ),
    ],
  ),

  // ── 15 ───────────────────────────────────────────────────
  TermsSection(
    numero: '15',
    titre: 'Force majeure',
    blocs: [
      Paragraphe(
        'Aucune partie ne saurait être tenue responsable d\'un '
        'manquement résultant d\'un cas de force majeure, notamment '
        'catastrophe naturelle, trouble à l\'ordre public, grève, '
        'coupure généralisée d\'électricité ou de réseau de '
        'télécommunications, ou décision d\'une autorité publique.',
      ),
    ],
  ),

  // ── 16 ───────────────────────────────────────────────────
  TermsSection(
    numero: '16',
    titre: 'Modification des CGU',
    blocs: [
      Paragraphe(
        'YAA se réserve le droit de modifier les présentes CGU afin de '
        'les adapter à l\'évolution des Services ou de la '
        'réglementation. La version applicable est celle en vigueur à '
        'la date d\'utilisation.',
      ),
      Paragraphe(
        'Toute modification substantielle est portée à la '
        'connaissance de l\'Utilisateur dans l\'Application. La '
        'poursuite de l\'utilisation vaut acceptation.',
      ),
    ],
  ),

  // ── 17 ───────────────────────────────────────────────────
  TermsSection(
    numero: '17',
    titre: 'Droit applicable et litiges',
    blocs: [
      Paragraphe(
        'Les présentes CGU sont régies par le droit de la République '
        'de Guinée.',
      ),
      Paragraphe(
        'En cas de différend, les parties s\'engagent à rechercher '
        'préalablement une solution amiable. À défaut d\'accord dans '
        'un délai de trente (30) jours à compter de la réclamation '
        'écrite, le litige sera porté devant les juridictions '
        'compétentes de Conakry.',
      ),
    ],
  ),

  // ── 18 ───────────────────────────────────────────────────
  TermsSection(
    numero: '18',
    titre: 'Contact',
    blocs: [
      Paragraphe(
        'Pour toute question relative aux présentes CGU :',
      ),
      Puces([
        'Courriel : $kEmail',
        'Téléphone : $kTelephone',
        'Adresse : $kSiege',
        'RCCM : $kRccm — NIF : $kNif',
      ]),
    ],
  ),
];
