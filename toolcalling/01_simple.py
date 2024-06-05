import os
import json
import requests 
from langchain_core.tools import tool
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_groq import ChatGroq
from langchain.agents import create_tool_calling_agent, AgentExecutor

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
SECTORS_API_KEY = os.getenv("SECTORS_API_KEY")

def retrieve_from_endpoint(url:str) -> dict:
    headers = {"Authorization": SECTORS_API_KEY}

    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()
    except requests.exceptions.HTTPError as err:
        raise SystemExit(err)
    return json.dumps(data)

# @tool decorator turns function into a tool
@tool
def get_company_overview(stock:str) -> str:
    """
    Get company overview from stock symbol. Returns:
        - Company name
        - Industry
        - Sector, Sub Sector
        - Market Cap
        - Last Close Price
        - Latest Close Date
        - Daily Close Change
        - 16 fields in total
    """
    url = f"https://api.sectors.app/v1/company/report/{stock}/?sections=overview"

    return retrieve_from_endpoint(url)

@tool
def get_top_companies_by_tx_volume(start_date:str, end_date:str, top_n:int=5) -> str:
    """
    Get top companies by transaction volume
    """
    url = f"https://api.sectors.app/v1/most-traded/?start={start_date}&end={end_date}&n_stock={top_n}"

    return retrieve_from_endpoint(url)

@tool
def get_daily_tx(stock:str, start_date:str, end_date:str) -> str:
    """
    Get daily transaction for a stock
    """
    url = f"https://api.sectors.app/v1/daily/{stock}/?start={start_date}&end={end_date}"

    return retrieve_from_endpoint(url)


query_1 = "What are the top 3 companies by transaction volume on the 4th, June 2024?"
query_2 = "Based on the closing prices of BREN between 1st and 31st of May, are we seeing an uptrend or downtrend? Try to explain why."
query_3 = "What is the company with the largest market cap between BBCA and BREN? For said company, retrieve the email, phone number, listing date and website for further research."

queries = [query_1, query_2, query_3]
tools = [get_top_companies_by_tx_volume, get_daily_tx, get_company_overview]

prompt = ChatPromptTemplate.from_messages([
    ("system", "Answer the following queries, being as factual and analytical as you can"),
    ("human", "{input}"),
    # msg containing previous agent tool invocations and corresponding tool outputs
    MessagesPlaceholder("agent_scratchpad"),
])

llm = ChatGroq(temperature=0, model_name="llama3-70b-8192", groq_api_key=GROQ_API_KEY)

agent = create_tool_calling_agent(llm, tools, prompt)
agent_executor = AgentExecutor(agent=agent, tools=tools, verbose=True)

for query in queries:
    print("Question:", query)
    result = agent_executor.invoke({"input": query})
    print("Answer:", "\n", result["output"], "\n\n======\n\n")

# verify answer:
#    https://sectors.app/stocks/most-traded