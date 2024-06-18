# superlexis

SICSS 2024 team working on LexisNexis data

## Problem notebook 

**Topic choice**
-   Difficult to narrow down the topic (the problem of overabundance)

    -   We ended up going with cycling!
    -   6 countries and 2 newspaper, but we faced rate limits so went to 4 countries with relevance.
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
- Translation through google API. We did this through Google Sheets, which we would recommend - super fast. Also possible through python code, but much faster online. 

End result
- DataFrame with standardized columns and a translated text 

**Data Processing **
- The key value of interest in 'text' code. _We do not do preprocessing here_, but rather work on the 

**Analysis**
- SNA.
- 
- Topic Model
- Sentiment analysis


