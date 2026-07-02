# bds-proj-2

- Student: `Mihajlo Madić 2119`
- Prezentacija:
  - PDF - [presentation.pdf](./docs/presentation/presentation.pdf);
  - Izvorni kod prezentacije (TeX) - [presentation.tex](./docs/presentation/presentation.tex).

Planirani sadržaj projekta:

- Docker-first stream analytics **arhitektura**: SUMO + Kafka + Spark Structured Streaming + Flink + consumer/map.
- Generisanje SUMO podataka za izabrani grad, uz FCD i emission output.
- Kafka tokovi za sirove i analitičke događaje.
- Paralelne Spark Structured Streaming i Flink aplikacije sa ekvivalentnom analitičkom logikom.
- Analitika zagađenja i saobraćajnog opterećenja u blizini značajnih prostornih entiteta iz OSM/Google Maps.
- Benchmark poređenje Spark i Flink implementacija nad istim workload i window konfiguracijama.
- Reproducibility checkpoint skripte dodaju se po fazama, nakon implementacije, verifikacije i odobrenja.
