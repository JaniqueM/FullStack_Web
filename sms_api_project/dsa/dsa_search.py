"""
Run with: python dsa_search.py
"""

import json
import time

# Loading transactions from the JSON file
with open("transactions.json", "r", encoding="utf-8") as f:
    transactions = json.load(f)

print(f" Loaded {len(transactions)} transactions\n")

# Method 1: Linear Search
# This goes through every single record one by one until it finds the right ID
# Like looking through every page of a book to find a word

def linear_search(transactions, target_id):
    """Searching through the list one by one until we find the ID."""
    for transaction in transactions:
        if transaction["id"] == target_id:
            return transaction
    return None  # Not found

# Method 2: Dictionary Lookup
# This stores all records in a dictionary where the key is the ID
# Like using the index at the back of a book to jump straight to the page

def build_lookup_dict(transactions):
    """Build a dictionary where key = id, value = transaction."""
    return {t["id"]: t for t in transactions}

def dict_lookup(lookup_dict, target_id):
    """Jump directly to the record using its ID as a key."""
    return lookup_dict.get(target_id, None)

# Build the dictionary once
lookup_dict = build_lookup_dict(transactions)

# Compare speed on 20 searches

# These are the 20 IDs we will search for
search_ids = [1, 50, 100, 200, 300, 400, 500, 600, 700, 800,
              900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1691, 999]

print("=" * 60)
print("         LINEAR SEARCH vs DICTIONARY LOOKUP")
print("=" * 60)
print(f"{'ID':<8} {'Linear (ms)':<20} {'Dict (ms)':<20} {'Winner'}")
print("-" * 60)

total_linear = 0
total_dict   = 0

for target_id in search_ids:

    # -- Time the linear search --
    start = time.perf_counter()
    result_linear = linear_search(transactions, target_id)
    end = time.perf_counter()
    linear_time = (end - start) * 1000  # Convert to milliseconds
    total_linear += linear_time

    # -- Time the dictionary lookup --
    start = time.perf_counter()
    result_dict = dict_lookup(lookup_dict, target_id)
    end = time.perf_counter()
    dict_time = (end - start) * 1000  # Convert to milliseconds
    total_dict += dict_time

    # -- Who won this round? --
    winner = " Dict" if dict_time < linear_time else " Linear"

    print(f"{target_id:<8} {linear_time:<20.6f} {dict_time:<20.6f} {winner}")

print("-" * 60)
print(f"{'TOTAL':<8} {total_linear:<20.6f} {total_dict:<20.6f}")
print(f"\n Dictionary was faster in most cases!")
print(f"   Total Linear time : {total_linear:.4f} ms")
print(f"   Total Dict time   : {total_dict:.4f} ms")

if total_dict < total_linear:
    speedup = total_linear / total_dict
    print(f"   Dictionary was {speedup:.1f}x faster overall!\n")

# Reflections
print("=" * 60)
print("                      REFLECTION")
print("=" * 60)
print("""
Question: Why is dictionary lookup faster than linear search?

Answer: Linear search checks every record one by one until it finds
   the right ID. If the record is near the end, it has to check
   all records before it. This is called O(n) time complexity where
   the more records you have, the slower it gets.

   Dictionary lookup uses a hash table internally. It calculates
   exactly where the record is stored and jumps straight to it.
   This is called O(1) time complexity where it takes the same 
   amount of time no matter how many records you have.

Question: Can you suggest another data structure or algorithm?

Answer: Yes! These options include:

   1. Binary Search — If records are sorted by ID, binary search
      splits the list in half each time. This is O(log n) which
      is much faster than linear but slightly slower than dict.

   2. Hash Map (same as Python dict) which is what we are 
      already using! Best for exact ID lookups with O(1) 
      average time.

   For this project, dictionary lookup is the best choice because
   we are searching by exact ID and Python dictionaries use hash
   maps internally.
""")
