# Analytics SQL Scripts : Insights & Reporting (Gold Layer)

[![SQL Server](https://img.shields.io/badge/SQL%20Server-2019+-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)](https://www.microsoft.com/en-us/sql-server)
[![Gold Layer](https://img.shields.io/badge/Layer-Gold-gold?style=for-the-badge)](../docs)
[![Analytics](https://img.shields.io/badge/Analytics-Reporting-blue?style=for-the-badge)](.)

## 📌 Resume Executif
Ce dossier regroupe 4 scripts SQL de la couche **Gold** pour l'analyse avancee, l'exploration et le reporting. Ils servent a produire des indicateurs business, segmentations et vues de reporting reutilisables pour la BI.

**Resultats Cles :**
* **Visibilite Rapide :** KPIs consolides et analyses temporelles prêtes a l'emploi.
* **Segmentation :** Clients et produits classes par performance et comportements.
* **Reporting Reutilisable :** Deux vues analytiques standardisees.

---

## 📂 Contenu du Dossier
### 1. Exploratory Analysis
Script: `Exploratory_analysis.sql`
- Exploration de schema et dimensions (tables, colonnes, valeurs distinctes).
- Bornes temporelles (order_date, ship_date, due_date) et dates clients/produits.
- KPIs de haut niveau a partir de `gold.fact_sales`.
- Analyses de magnitude par pays, genre, categorie et clients.

### 2. Advanced Analytics
Script: `Advanced_data_analytics.sql`
- Tendances temporelles (annee, mois, periode) basees sur `gold.fact_sales`.
- Analyses cumulatives (ventes et prix) a partir des dates de commande.
- Performance produit avec comparaison a la moyenne et evolution annuelle.
- Contribution au total par categorie (part-to-whole).
- Segmentation clients et segmentation des couts produits.

### 3. Reporting Clients
Script: `report_customers.sql`
- Vue `gold.report_customers` (agregation a partir de `gold.fact_sales` et `gold.dim_customers`).
- Segmentation par age et comportement d'achat.
- Recence, frequence, valeur moyenne et depense mensuelle.

### 4. Reporting Produits
Script: `report_products.sql`
- Vue `gold.report_products` (agregation a partir de `gold.fact_sales` et `gold.dim_products`).
- Recence, volume, chiffre d'affaires, prix moyen.
- Segmentation de performance produit.

---

## 🔗 Donnees & Relations Utilisees
Les analyses s'appuient sur le modele en etoile de la couche Gold, alimente par les sources CRM et ERP.

**Tables principales :**
* `gold.fact_sales` : ventes (order_date, ship_date, due_date, sales, quantity, price, product_key, customer_key).
* `gold.dim_customers` : clients (country, gender, birth_date, customer_number).
* `gold.dim_products` : produits (category, subcategory, cost, start_date, end_date).

**Relations utilisees :**
* `gold.fact_sales.customer_key` -> `gold.dim_customers.customer_key`.
* `gold.fact_sales.product_key` -> `gold.dim_products.product_key`.

**Logique d'analyse :**
* Les tendances temporelles proviennent des dates de commande de `gold.fact_sales`.
* Les segmentations clients combinent volume d'achat et anciennete (mois actifs).
* Les performances produits comparent les ventes annuelles a la moyenne par produit.
* Les contributions par categorie calculent la part relative des ventes totales.

---

## 🧭 Structure Standard des Scripts
Chaque script suit un format harmonise :
- En-tete descriptif (purpose, actions, usage).
- Sections logiques avec commentaires clairs.
- Requetes independantes pour execution au besoin.

---

## 🚀 Installation & Usage
### Prerequis
* SQL Server 2019+.
* Schema `gold` et tables/vues dimensionnelles disponibles.

### Execution
Ouvrir un script et executer les sections utiles selon le besoin :
```sql
-- Exemple : lancer un reporting client
SELECT TOP 100 * FROM gold.report_customers;
```

---

## 📈 Exemples d'Analyses
```sql
-- Top 5 produits par chiffre d'affaires
SELECT TOP 5
    product_name,
    total_sales
FROM gold.report_products
ORDER BY total_sales DESC;

-- Segmentation clients et depense moyenne
SELECT
    customer_behavioral_segment,
    AVG(avg_order_value) AS avg_order_value
FROM gold.report_customers
GROUP BY customer_behavioral_segment;
```

---

## ✅ Bonnes Pratiques
* Executer les requetes par section pour limiter les charges.
* Utiliser les vues `gold.report_*` pour l'analyse BI.
* Enrichir les segments selon les besoins metier.

---

## 👤 Contact

**Douha Majri** *Élève Ingénieure à l'École Centrale Casablanca* *Spécialisée en Analytics Engineering & Data Architecture*

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](www.linkedin.com/in/douha-majri)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Douha-MAJRI)

---
*Dernière mise à jour : Février 2026*

