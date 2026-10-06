# NavMarket Ops

> Je construis et j'exploite, de bout en bout, la plateforme d'une boutique en ligne : du premier serveur Linux jusqu'à Kubernetes sur AWS.
> Chaque étape est un lab réel, documenté, avec sa preuve.

**Parcours en cours : séance 1 / 24** · [Voir ma progression en direct](https://nava-techn.github.io/navmarket-roadmap/)
**LinkedIn :** [Write_me_on_linkdin_and_i_answer_to_you](https://www.linkedin.com/in/valdes-nague/)

---

## Le projet

**NavMarket** est une start-up fictive qui vend en ligne des produits de chez Navatech. J'en suis le premier ingénieur d'exploitation (Ops) : je mets en place les serveurs, le réseau, la sécurité, le déploiement et la supervision de sa boutique.

Le parcours suit l'ordre d'une vraie plateforme qui grandit :

| Phase | Séances | Thème |
| --- | --- | --- |
| Fondations | 1 à 8 | Linux, réseau, Bash et Python, virtualisation, Git |
| Application | 9 à 10 | API NestJS + front Next.js + PostgreSQL |
| Conteneurs et CI/CD | 11 à 12 | Docker, GitHub Actions |
| Cloud AWS | 13 à 16 | IAM, VPC, EC2, RDS, ECS Fargate |
| Infrastructure as Code | 17 à 18 | Terraform, Ansible |
| Kubernetes | 19 à 21 | kind, Helm, Argo CD, EKS, CKA |
| Observabilité et projet final | 22 à 24 | Prometheus, Grafana, Loki, postmortem |

## Labs réalisés

Chaque lab a sa fiche dans `docs/` : objectif, démarche, preuve, problème rencontré, ce que j'ai appris.

| Séance | Lab | Fiche | Statut |
| --- | --- | --- | --- |
| 1 | Poste de travail Linux (Ubuntu 26.04 LTS en dual boot) | — | ✅ |

*Ce tableau est complété à chaque lab validé.*

## Organisation du dépôt

```
navmarket-ops/
├── README.md      ← cette page
├── docs/          ← une fiche par lab, rangées par séance
├── scripts/       ← scripts Bash et Python d'exploitation
├── nginx/         ← configurations du serveur web
└── site/          ← la vitrine NavMarket
```

*Cette structure s'enrichit au fil des séances.*

## Méthode

- **Je tape et je comprends chaque commande** : rien n'est copié sans être expliqué dans la fiche du lab.
- **Une preuve par lab** : capture, sortie de commande ou lien vers le service en ligne.
- **Des pannes provoquées puis réparées** : certains labs cassent volontairement quelque chose pour apprendre à diagnostiquer.
- **Aucun secret dans ce dépôt** : ni mot de passe, ni clé, ni adresse de serveur (voir `.gitignore`).

## Contact

- Progression : [voir_ma_progression](https://nava-techn.github.io/navmarket-roadmap/)
- GitHub : [Mon_Github](https://github.com/nava-techn)
- LinkedIn : [Write_me_on_linkdin_and_i_answer_to_you](https://www.linkedin.com/in/valdes-nague/)
