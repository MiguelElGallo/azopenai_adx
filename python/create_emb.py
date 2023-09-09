import openai
import pandas as pd
import tiktoken
import re

# Reads the records from the last level of the hierarchy

# Load data into pandas DataFrame from "/lakehouse/default/" + "Files/masterdata/product_hier/dairy_products.csv"
df = pd.read_csv("./python/" + "dairy_products.csv")
print(df.head())

# Create new column text_to_embedd
df['text_to_embedd'] = "Category: " + df['product_hier'].map(str) + ". " + "Description:" + df['description'].map(str)
print(df.head())


# Now let's prepare to call the OpenAI model to generate and embedding


from openai.embeddings_utils import get_embedding, cosine_similarity
import tiktoken

# s is input text , and all special characters are removed. Including double spaces, double dots, etc.
def normalize_text(s, sep_token = " \n "):
    s = re.sub(r'\s+',  ' ', s).strip()
    s = re.sub(r". ,","",s)
    # remove all instances of multiple spaces
    s = s.replace("..",".")
    s = s.replace(". .",".")
    s = s.replace("\n", "")
    s = s.strip()
    return s

# We need to use tokenizer to get the number of tokens before calling the embedding
tokenizer = tiktoken.get_encoding("cl100k_base")

openai.api_type = "azure"
openai.api_base = ""
openai.api_version = "2023-03-15-preview"
openai.api_key = "f" #Never share this key with anyone or leave it in a notebook, repo, etc.

# remove double spaces, dots, etc.
df['text_to_embedd'] = df['text_to_embedd'].apply(lambda x : normalize_text(x))
# add new column with number of tokens
df['n_tokens'] = df["text_to_embedd"].apply(lambda x: len(tokenizer.encode(x)))


#Now we call the OpenAI A, model for getting the embeddings
df['vector'] = df["text_to_embedd"].apply(lambda x : get_embedding(x, engine = 'embedding')) # engine should be set to the deployment name you chose when you deployed the text-embedding-ada-002 (Version 2) model

print(df.head())


