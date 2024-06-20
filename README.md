# superlexis

SICSS 2024 team working on LexisNexis data

## Problem notebook 
1.  Main problem relates to the **representation and the size of our sample**; there is a download limit imposed by Nexis Uni, which was not explicity mentioned anywhere -> we figured that out after the plan was already agreed upon. This led to further complications:
  - Thinking that we can download everyhthing we did not think about issues of representation -> ended up with a skewed distribution for some countries
  - This might also be the case for the year of publication
  - Clearly, we could've fixed these issues at a later point thorugh a better use of the filters if it wasn't for the download limit

2. Another problem relates to the choice of keywords; we later realized that 'cycle*' can have alternative and unrelated meanings: e.g. electoral cycle
   
**Topic choice**
-   Difficult to narrow down the topic (the problem of overabundance)

    - We ended up going with cycling 🚴🏻
    - 6 countries, 2 newspapers per country (left- and right-leaning), with about 1000 articles per country due to Nexis Uni limits.
    - This leads to problems such as
    - Unbalanced classes.
    - How to pick up online or print versions?
    - Limited to the individual files - we had to take away the cover page (more flexible code would work only on defaults on the)
    - Selecting the keywords on different language (Hannah's substance expertize and ChatGPT) 
 
**Data import**

Difficult to parse LexisNexis to a usable dataframe
-  Some handcrafted code for import (thanks Roeland!)
-  We still had to have additional code to fix columns (Leevi), harmonize standardize datenames (Polina
- etc. Toolbox of helper functions as scripts - needs to still be factored     
- Translation through Google API. We did this through Google Sheets, which we would recommend - super fast. Also possible through python code, but much faster online. 
- End result: dataframe with standardized columns and a translated text.

**Data Processing**
- The key value of interest in 'text' code. _We do not do preprocessing here_, but rather work on the:

**Analysis**
- Social Network Analysis: cities,
- Topic Models: LDA and STM,
- Sentiment analysis (NRC, Rauh, Vader and Polarity lexicons + SiEBERT, a fine-tuned checkpoint of RoBERTa),

**What did not happen (yet!)**
- Roeland ried to do apply novel quantitative text analysis techniques in **MoreThanSentiments**, developed at Walmart in 2022 https://pypi.org/project/MoreThanSentiments/. However, already such a new package faces installation issues. Seemed like an interesting package to work with but not possible to work on this in these time constraints

