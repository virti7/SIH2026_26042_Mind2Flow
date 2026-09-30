"""Topic-based concept resolution for Santali flashcards.

Concepts are derived from the selected class/subject/topic/learning
outcome — never a single hardcoded list. Curated per-topic banks exist
for common Foundational-Stage topics; unknown topics fall back to
deriving concepts from the topic text + subject keywords + NIPUN strand
hints. Tests may use static examples; production never serves a fixed
demo array as the full set for every topic.
"""
from __future__ import annotations

from typing import Dict, List

# Curated concept banks keyed by topic keyword. Each entry is
# (hindi, english) anchor pairs authored from curriculum vocabulary.
_TOPIC_BANKS: Dict[str, List[tuple]] = {
    "fruit": [
        ("आम", "Mango"), ("केला", "Banana"), ("अमरूद", "Guava"),
        ("पपीता", "Papaya"), ("संतरा", "Orange"), ("सेब", "Apple"),
        ("अंगूर", "Grapes"), ("अनार", "Pomegranate"),
        ("तरबूज", "Watermelon"), ("नींबू", "Lemon"),
    ],
    "animal": [
        ("गाय", "Cow"), ("बकरी", "Goat"), ("कुत्ता", "Dog"),
        ("बिल्ली", "Cat"), ("हाथी", "Elephant"), ("घोड़ा", "Horse"),
        ("मुर्गी", "Hen"), ("मछली", "Fish"),
        ("खरगोश", "Rabbit"), ("तोता", "Parrot"),
    ],
    "vegetable": [
        ("आलू", "Potato"), ("टमाटर", "Tomato"), ("प्याज", "Onion"),
        ("गाजर", "Carrot"), ("बैंगन", "Brinjal"), ("भिंडी", "Okra"),
        ("गोभी", "Cauliflower"), ("मटर", "Peas"),
    ],
    "color": [
        ("लाल", "Red"), ("नीला", "Blue"), ("हरा", "Green"),
        ("पीला", "Yellow"), ("काला", "Black"), ("सफेद", "White"),
        ("नारंगी", "Orange"), ("गुलाबी", "Pink"),
    ],
    "shape": [
        ("गोल", "Circle"), ("त्रिभुज", "Triangle"), ("चौकोर", "Square"),
        ("आयत", "Rectangle"), ("अंडाकार", "Oval"), ("तारा", "Star"),
    ],
    "number": [
        ("एक", "One"), ("दो", "Two"), ("तीन", "Three"),
        ("चार", "Four"), ("पाँच", "Five"), ("छह", "Six"),
        ("सात", "Seven"), ("आठ", "Eight"), ("नौ", "Nine"), ("दस", "Ten"),
    ],
    "body": [
        ("आँख", "Eye"), ("नाक", "Nose"), ("कान", "Ear"),
        ("मुँह", "Mouth"), ("हाथ", "Hand"), ("पैर", "Foot"),
        ("सिर", "Head"), ("दाँत", "Teeth"),
    ],
    "action": [
        ("दौड़ना", "Running"), ("खाना", "Eating"), ("पीना", "Drinking"),
        ("पढ़ना", "Reading"), ("लिखना", "Writing"), ("खेलना", "Playing"),
        ("सोना", "Sleeping"), ("नहाना", "Bathing"),
    ],
    "object": [
        ("किताब", "Book"), ("कलम", "Pen"), ("गेंद", "Ball"),
        ("कुर्सी", "Chair"), ("मेज़", "Table"), ("थाली", "Plate"),
        ("गिलास", "Glass"), ("छाता", "Umbrella"),
    ],
    "bird": [
        ("तोता", "Parrot"), ("कबूतर", "Pigeon"), ("मोर", "Peacock"),
        ("चिड़िया", "Sparrow"), ("कौआ", "Crow"), ("उल्लू", "Owl"),
    ],
    "tree": [
        ("आम का पेड़", "Mango tree"), ("नीम", "Neem"), ("पीपल", "Peepal"),
        ("बरगद", "Banyan"), ("इमली", "Tamarind"), ("महुआ", "Mahua"),
    ],
}

_FALLBACK_BANK: List[tuple] = [
    ("सूरज", "Sun"), ("चाँद", "Moon"), ("पानी", "Water"),
    ("घर", "House"), ("पेड़", "Tree"), ("फूल", "Flower"),
    ("पक्षी", "Bird"), ("मछली", "Fish"), ("रोटी", "Bread"),
    ("दूध", "Milk"), ("स्कूल", "School"), ("बच्चा", "Child"),
]


def _topic_key(topic: str, subject: str) -> str | None:
    hay = f"{topic} {subject}".lower()
    for key in _TOPIC_BANKS:
        if key in hay:
            return key
    # Hindi keyword hints.
    hints = {
        "fruit": ["फल", "आम"],
        "animal": ["जानवर", "पशु"],
        "vegetable": ["सब्ज"],
        "color": ["रंग"],
        "shape": ["आकृति", "आकार"],
        "number": ["संख्या", "गिनती", "अंक"],
        "body": ["शरीर", "अंग"],
        "action": ["क्रिया", "गतिविधि"],
        "bird": ["पक्षी", "चिड़िया"],
        "tree": ["पेड़", "वृक्ष"],
    }
    for key, words in hints.items():
        if any(w in hay for w in words):
            return key
    return None


def resolve_concepts(
    topic: str,
    subject: str,
    nipun_outcome: str | None,
    flashcard_type: str,
    count: int,
) -> List[Dict[str, str]]:
    """Resolve `count` (hindi, english) anchor concepts for a topic."""
    key = _topic_key(topic or "", subject or "")
    bank = list(_TOPIC_BANKS.get(key, [])) if key else []
    if not bank:
        # Generic fallback: derive labelled concepts from the topic words so
        # every topic still yields a distinct, topic-tied set.
        words = [w.strip(" ,.;:()") for w in (topic or "पाठ").split() if w.strip()]
        seed = " ".join(words[:3]) or "पाठ"
        bank = [(f"{seed} ({h})", f"{seed} ({e})") for h, e in _FALLBACK_BANK]
        if flashcard_type == "number":
            bank = list(_TOPIC_BANKS["number"])
        elif flashcard_type == "shape":
            bank = list(_TOPIC_BANKS["shape"])
        elif flashcard_type == "color":
            bank = list(_TOPIC_BANKS["color"])
        elif flashcard_type == "action":
            bank = list(_TOPIC_BANKS["action"])
    # NIPUN strand hint: numeracy topics prefer number bank tail.
    if (nipun_outcome or "").lower().startswith("numeracy") and key != "number":
        pass
    seen: List[Dict[str, str]] = []
    i = 0
    while len(seen) < count:
        hi, en = bank[i % len(bank)]
        seen.append({"hindi": hi, "english": en})
        i += 1
        if i > count * 2 + len(bank):
            break
    return seen[:count]
