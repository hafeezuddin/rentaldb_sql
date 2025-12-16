/* Business Problem: Customer Retention & Loyalty Program Optimization
 Business Context:The DVD rental company is facing increased competition from streaming services. 
 They want to launch a targeted loyalty program to retain their most valuable customers and win back at-risk customers.
 
 Business Questions:
 "Who are our most valuable customers and what are their rental patterns?"
 "Which customers are at risk of churning based on declining activity?"
 "What film categories and actors drive the most customer loyalty?"
 "How should we segment customers for targeted marketing campaigns?"
 
 Available Data (Sakila Schema):
 Customer Demographics: customer table with join dates
 Rental History: rental table with timestamps
 Payment Data: payment table for customer lifetime value
 Film Preferences: film, film_category, category tables
 Actor Preferences: film_actor, actor tables
 Store Locations: store, address tables for geographic patterns
 
 Analytical Framework:
 Metric 1: Customer Value Scoring:
 Recency, Frequency, Customer Lifetime Value calculation, 
 Monetary (RFM) analysis - Based on total_money_spent, total_rentals, days_since_last_rental
 Rental frequency trends over time
 
 Metric 2: Churn Risk Assessment:
 Months since last rental
 Rental frequency decline rate
 Payment pattern changes
 
 Metric 3: Content Preference Analysis:
 Favorite categories per customer segment
 Actor popularity across value tiers
 Seasonal rental patterns
 
 Required Deliverables:
 Customer segmentation with clear value tiers
 Churn risk scoring with at-risk customer list
 Personalized film recommendations for each segment
 Loyalty program structure with tier-specific benefits
 Expected ROI for retention campaigns */
