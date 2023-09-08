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
openai.api_base = "https://cog-w4xj3n733yecm.openai.azure.com/"
openai.api_version = "2023-03-15-preview"
openai.api_key = "fea005af52984d1a84d44c1e164de3de" #Never share this key with anyone or leave it in a notebook, repo, etc.

# remove double spaces, dots, etc.
df['text_to_embedd'] = df['text_to_embedd'].apply(lambda x : normalize_text(x))
# add new column with number of tokens
df['n_tokens'] = df["text_to_embedd"].apply(lambda x: len(tokenizer.encode(x)))


#Now we call the OpenAI A, model for getting the embeddings
df['vector'] = df["text_to_embedd"].apply(lambda x : get_embedding(x, engine = 'embedding')) # engine should be set to the deployment name you chose when you deployed the text-embedding-ada-002 (Version 2) model

print(df.head())


cluster = "https://decw4xj3n733yecm.eastus.kusto.windows.net"

# In case you want to authenticate with AAD application.
client_id = "690bfb4e-636b-4dee-907b-cb68c0f6d2b5"
client_secret = "<insert here your AAD application key>"

# read more at https://docs.microsoft.com/en-us/onedrive/find-your-office-365-tenant-id
authority_id = "8d964df9-4277-43e2-afea-d8e5e176ca50" 

kcsb = KustoConnectionStringBuilder.with_aad_application_key_authentication(cluster, client_id, client_secret, authority_id)

client = QueuedIngestClient(kcsb)

# there are a lot of useful properties, make sure to go over docs and check them out
ingestion_props = IngestionProperties(
    database="{database_name}",
    table="{table_name}",
    data_format=DataFormat.CSV,
    # in case status update for success are also required (remember to import ReportLevel from azure.kusto.ingest)
    # report_level=ReportLevel.FailuresAndSuccesses,
    # in case a mapping is required (remember to import IngestionMappingKind from azure.kusto.data.data_format)
    # ingestion_mapping_reference="{json_mapping_that_already_exists_on_table}",
    # ingestion_mapping_kind= IngestionMappingKind.JSON,
)

###########################
## ingest from dataframe ##
###########################

import pandas

fields = ["id", "name", "value"]
rows = [[1, "abc", 15.3], [2, "cde", 99.9]]

df = pandas.DataFrame(data=rows, columns=fields)

client.ingest_from_dataframe(df, ingestion_properties=ingestion_props)