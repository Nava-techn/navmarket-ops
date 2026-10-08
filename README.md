# NavMarket Ops

> I build and run, end to end, the platform behind an online shop: from the very first Linux server all the way to Kubernetes on AWS.
> Every step is a real lab, documented, with proof.

**Current progress: session 1 / 24** · [See my live progress](https://nava-techn.github.io/navmarket-roadmap/)
**LinkedIn:** [Write to me on LinkedIn, I'll answer](https://www.linkedin.com/in/valdes-nague/)

---

## The project

**NavMarket** is a fictional start-up that sells Navatech products online. I am its first operations (Ops) engineer: I set up the servers, the network, security, deployment and monitoring for its shop.

The learning path follows the order in which a real platform grows:

| Phase | Sessions | Topic |
| --- | --- | --- |
| Foundations | 1 to 8 | Linux, networking, Bash and Python, virtualization, Git |
| Application | 9 to 10 | NestJS API + Next.js front end + PostgreSQL |
| Containers and CI/CD | 11 to 12 | Docker, GitHub Actions |
| AWS Cloud | 13 to 16 | IAM, VPC, EC2, RDS, ECS Fargate |
| Infrastructure as Code | 17 to 18 | Terraform, Ansible |
| Kubernetes | 19 to 21 | kind, Helm, Argo CD, EKS, CKA |
| Observability and final project | 22 to 24 | Prometheus, Grafana, Loki, postmortem |

## Completed labs

Each lab has its own write-up in `docs/`: goal, approach, proof, problem encountered, what I learned.

| Session | Lab | Write-up | Status |
| --- | --- | --- | --- |
| 1 | Linux workstation (Ubuntu 26.04 LTS in dual boot) | — | ✅ |
| 1 | S1.1 First server `navmarket-srv01`: Ubuntu Server 26.04.1 LTS on KVM/libvirt, administered over SSH, fully updated, snapshot | [S1.1](docs/session-01/S1.1-first-server.md) | ✅ |

*This table is updated every time a lab is completed.*

## Repository layout

```
navmarket-ops/
├── README.md      ← this page
├── docs/          ← one write-up per lab, organized by session
├── scripts/       ← Bash and Python operations scripts
├── nginx/         ← web server configurations
└── site/          ← the NavMarket storefront
```

*This structure grows session by session.*

## Method

- **I type and understand every command**: nothing is copied without being explained in the lab write-up.
- **One proof per lab**: a screenshot, a command output or a link to the live service.
- **Failures caused on purpose, then fixed**: some labs deliberately break something so I learn to troubleshoot.
- **No secrets in this repository**: no passwords, no keys, no server addresses (see `.gitignore`).

## Contact

- Progress: [See my progress](https://nava-techn.github.io/navmarket-roadmap/)
- GitHub: [My GitHub](https://github.com/nava-techn)
- LinkedIn: [Write to me on LinkedIn, I'll answer](https://www.linkedin.com/in/valdes-nague/)
