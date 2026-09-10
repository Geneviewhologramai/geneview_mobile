import wikipediaapi
from duckduckgo_search import DDGS

wiki = wikipediaapi.Wikipedia(
    language='hu',
    user_agent='GeneviewAssistant/1.0 (contact@geneview.local)'
)

def search_wikipedia(query: str) -> str | None:
    page = wiki.page(query)
    if page.exists():
        sentences = page.summary.split('. ')
        clean_summary = ". ".join(sentences[:2]).strip()
        if not clean_summary.endswith('.'):
            clean_summary += '.'
        return clean_summary
    return None

def search_duckduckgo(query: str) -> str | None:
    try:
        with DDGS() as ddgs:
            results = list(ddgs.text(query, region='hu-hu', max_results=1))
            if results:
                return results[0].get('body', '')
    except Exception:
        pass
    return None

def fetch_web_knowledge(query: str) -> str:
    wiki_result = search_wikipedia(query)
    if wiki_result:
        return wiki_result
    ddg_result = search_duckduckgo(query)
    if ddg_result:
        return ddg_result
    return "Sajnos az interneten sem találtam egyértelmű választ a kérdésedre."
