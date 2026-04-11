/* The Operations team needs to reduce inventory costs while maintaining customer satisfaction.
 They want data-driven recommendations on which films to keep, which to acquire more copies of, and which to phase out.

 Business Questions:
 "Which films give us the best return on our inventory investment?"
 "Are we over-invested in some films and under-invested in others?"
 "When do we need more copies available to meet demand?"
 "What's the optimal inventory mix for maximum profitability?"

 Analytical Framework:

 Metric 1: Film Profitability Score
 Calculate return on inventory investment for each film.
 Components:
 Revenue per Copy = Total film revenue / Number of copies
 Cost Recovery Multiple = Total revenue / Total replacement cost
 Rental Efficiency = Rentals per copy per month

 Metric 2: Demand Patterns & Seasonality
 Identify when and how films are rented.
 Components:
 Monthly Rental Patterns - Peak demand periods
 Rental Duration Analysis - How long films stay out
 Copy Utilization Rate - How intensely each copy is used

 Film Tiering System:
 Tier 1: "Workhorses" - High utilization, high ROI
 Tier 2: "Sleepers" - Low utilization but profitable when rented
 Tier 3: "Opportunities" - High demand, need more copies
 Tier 4: "Cost Centers" - Expensive but rarely rented
 Tier 5: "Underperformers" - Low cost but also low usage

 Tier Classification Framework

 Tier 1: "Workhorses" - High Utilization, High ROI
 Criteria:
 Revenue per copy > 75th percentile
 Cost recovery multiple > 3.0
 Average monthly rentals per copy > 2
 Action: Maintain current copies, monitor for wear

 Tier 2: "Sleepers" - Low Utilization but Profitable
 Criteria:
 Revenue per copy > 60th percentile
 Cost recovery multiple > 2.0
 Average monthly rentals per copy < 1.5
 Action: Keep but don't expand, potential for promotion

 Tier 3: "Opportunities" - High Demand, Need More Copies
 Criteria:
 Peak month concentration > 30% (high seasonal demand)
 Revenue per copy > 50th percentile
 Current copies < 3 (undersupplied)
 Action: Increase copy count by 1-2 copies

 Tier 4: "Cost Centers" - Expensive but Rarely Rented
 Criteria:
 Replacement cost > 75th percentile
 Cost recovery multiple < 1.5
 Average monthly rentals per copy < 1
 Action: Phase out, reduce to 1 copy

 Tier 5: "Underperformers" - Low Cost, Low Usage
 Criteria:
 Revenue per copy < 25th percentile
 Cost recovery multiple < 1.0
 Average monthly rentals per copy < 0.5
 Action: Remove excess copies, keep minimum only

 Required Deliverables:
 Film-tier recommendations with specific copy count changes
 Expected financial impact of optimization
 */
--CTE to retrieve core metrics for each film (#Integrated)