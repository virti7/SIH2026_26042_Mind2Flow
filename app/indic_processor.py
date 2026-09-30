"""Faithful pure-Python statement of the IndicTransToolkit ``IndicProcessor``.

The IndicTrans2 *indic-indic* models expect input sentences to be prepared with
an ``IndicProcessor``: punctuation/numeral normalisation, tokenisation, script
handling, and a ``src tgt`` language-tag prefix; output is post-processed after
decoding (script transliteration + detokenisation).

The official ``IndicTransToolkit`` ships this as a Cython extension with no
Windows wheels, so this module reproduces the published algorithm
(IndicTransToolkit processor.pyx, MIT licensed) in pure Python. The external
Santali translation API uses the very same algorithm, which keeps the local
engine's output consistent with it.

Only the languages used here (Hindi ``hin_Deva``, Santali ``sat_Olck``)
are exercised; the implementation keeps the general structure of the original.
"""

from __future__ import annotations

import re

from sacremoses import (
    MosesDetokenizer,
    MosesPunctNormalizer,
    MosesTokenizer,
)

from indicnlp.normalize.indic_normalize import IndicNormalizerFactory
from indicnlp.tokenize import indic_detokenize, indic_tokenize
from indicnlp.transliterate.unicode_transliterate import UnicodeIndicTransliterator


class IndicProcessor:
    def __init__(self, inference: bool = True):
        self.inference = inference

        # FLORES-200 code -> ISO language code used by IndicNLP. Only the two
        # languages of this project are strictly required.
        self._flores_codes = {
            "hin_Deva": "hi",
            "sat_Olck": "or",
            "eng_Latn": "en",
        }

        # Numerals from every Indic script -> ASCII.
        digits = {
            "\u09e6": "0", "\u0ae6": "0", "\u0ce6": "0", "\u0966": "0",
            "\u0660": "0", "\uabf0": "0", "\u0b66": "0", "\u0a66": "0",
            "\u1c50": "0", "\u06f0": "0",
            "\u09e7": "1", "\u0ae7": "1", "\u0967": "1", "\u0ce7": "1",
            "\u06f1": "1", "\uabf1": "1", "\u0b67": "1", "\u0a67": "1",
            "\u1c51": "1", "\u0c67": "1",
            "\u09e8": "2", "\u0ae8": "2", "\u0968": "2", "\u0ce8": "2",
            "\u06f2": "2", "\uabf2": "2", "\u0b68": "2", "\u0a68": "2",
            "\u1c52": "2", "\u0c68": "2",
            "\u09e9": "3", "\u0ae9": "3", "\u0969": "3", "\u0ce9": "3",
            "\u06f3": "3", "\uabf3": "3", "\u0b69": "3", "\u0a69": "3",
            "\u1c53": "3", "\u0c69": "3",
            "\u09ea": "4", "\u0aea": "4", "\u096a": "4", "\u0cea": "4",
            "\u06f4": "4", "\uabf4": "4", "\u0b6a": "4", "\u0a6a": "4",
            "\u1c54": "4", "\u0c6a": "4",
            "\u09eb": "5", "\u0aeb": "5", "\u096b": "5", "\u0ceb": "5",
            "\u06f5": "5", "\uabf5": "5", "\u0b6b": "5", "\u0a6b": "5",
            "\u1c55": "5", "\u0c6b": "5",
            "\u09ec": "6", "\u0aec": "6", "\u096c": "6", "\u0cec": "6",
            "\u06f6": "6", "\uabf6": "6", "\u0b6c": "6", "\u0a6c": "6",
            "\u1c56": "6", "\u0c6c": "6",
            "\u09ed": "7", "\u0aed": "7", "\u096d": "7", "\u0ced": "7",
            "\u06f7": "7", "\uabf7": "7", "\u0b6d": "7", "\u0a6d": "7",
            "\u1c57": "7", "\u0c6d": "7",
            "\u09ee": "8", "\u0aee": "8", "\u096e": "8", "\u0cee": "8",
            "\u06f8": "8", "\uabf8": "8", "\u0b6e": "8", "\u0a6e": "8",
            "\u1c58": "8", "\u0c6e": "8",
            "\u09ef": "9", "\u0aef": "9", "\u096f": "9", "\u0cef": "9",
            "\u06f9": "9", "\uabf9": "9", "\u0b6f": "9", "\u0a6f": "9",
            "\u1c59": "9", "\u0c6f": "9",
        }
        self._digits_table = {ord(k): v for k, v in digits.items()}
        for ch in range(ord("0"), ord("9") + 1):
            self._digits_table[ch] = chr(ch)

        self._en_tok = MosesTokenizer(lang="en")
        self._en_norm = MosesPunctNormalizer(lang="en")
        self._en_detok = MosesDetokenizer(lang="en")
        self._xliterator = UnicodeIndicTransliterator()

        self._MULTISPACE = re.compile(r"[ ]{2,}")
        self._PUNC_REPLACEMENTS = [
            (re.compile(r"\r"), ""),
            (re.compile(r"\(\s*"), "("),
            (re.compile(r"\s*\)"), ")"),
            (re.compile(r"\s:\s?"), ":"),
            (re.compile(r"\s;\s?"), ";"),
            (re.compile(r"[`´‘‚’]"), "'"),
            (re.compile(r"[„“”«»]"), '"'),
            (re.compile(r"[–—]"), "-"),
            (re.compile(r"\.\.\."), "..."),
            (re.compile(r"\u00a0%"), "%"),
            (re.compile(r"nº\u00a0"), "nº "),
            (re.compile(r"\u00a0ºC"), " ºC"),
            (re.compile(r"\u00a0[?!;]"), lambda m: m.group(0).strip()),
            (re.compile(r",\u00a0"), ", "),
        ]
        self._URL_PATTERN = re.compile(
            r"\b(?<![\w/.])(?:(?:https?|ftp)://)?(?:(?:[\w-]+\.)+(?!\.))(?:[\w/\-?#&=%.]+)+(?!\.\w+)\b"
        )
        self._NUMERAL_PATTERN = re.compile(
            r"(~?\d+\.?\d*\s?%?\s?-?\s?~?\d+\.?\d*\s?%|~?\d+%|\d+[-\/.,:']\d+[-\/.,:'+]\d+(?:\.\d+)?|\d+[-\/.:'+]\d+(?:\.\d+)?)"
        )
        self._EMAIL_PATTERN = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}")
        self._OTHER_PATTERN = re.compile(r"[A-Za-z0-9]*[#|@]\w+")

        self._placeholder_maps: list[dict[str, str]] = []

    # ---------------------------- internals ---------------------------------
    def _punc_norm(self, text: str) -> str:
        for pattern, repl in self._PUNC_REPLACEMENTS:
            text = pattern.sub(repl, text)
        text = self._MULTISPACE.sub(" ", text)
        return text.strip()

    def _wrap_entities(self, text: str) -> str:
        serial = 1
        entity_map: dict[str, str] = {}
        for pattern in (self._EMAIL_PATTERN, self._URL_PATTERN, self._NUMERAL_PATTERN, self._OTHER_PATTERN):
            for match in set(pattern.findall(text)):
                if pattern is self._URL_PATTERN and len(match.replace(".", "")) < 4:
                    continue
                if pattern is self._NUMERAL_PATTERN and len(
                    match.replace(" ", "").replace(".", "").replace(":", "")
                ) < 4:
                    continue
                base = f"<ID{serial}>"
                for fmt in (
                    f"<ID{serial}>", f"< ID{serial} >", f"[ID{serial}]",
                    f"[ ID{serial} ]", f"[ID {serial}]", f"<ID{serial}]",
                    f"< ID{serial}]", f"<ID{serial} ]",
                    f"<id{serial}>", f"< id{serial} >", f"[id{serial}]",
                    f"[ id{serial} ]", f"[id {serial}]", f"<id{serial}]",
                    f"< id{serial}]", f"<id{serial} ]",
                ):
                    entity_map[fmt] = match
                text = text.replace(match, base)
                serial += 1
        text = re.sub(r"\s+", " ", text).replace(">/", ">").replace("]/", "]")
        self._placeholder_maps.append(entity_map)
        return text

    def _normalize(self, text: str) -> str:
        text = text.translate(self._digits_table)
        if self.inference:
            text = self._wrap_entities(text)
        return text

    def _indic_tokenize_transliterate(
        self, sentence: str, normalizer, iso_lang: str, transliterate: bool
    ) -> str:
        normed = normalizer.normalize(sentence.strip())
        tokens = indic_tokenize.trivial_tokenize(normed, iso_lang)
        joined = " ".join(tokens)
        if transliterate:
            joined = self._xliterator.transliterate(joined, iso_lang, "hi")
            joined = joined.replace(" ् ", "्")
        return joined

    def _preprocess(self, sent, src_lang, tgt_lang, normalizer, is_target) -> str:
        iso_lang = self._flores_codes.get(src_lang, "hi")
        script = src_lang.split("_")[1]
        transliterate = True
        if script in ("Arab", "Aran", "Olck", "Mtei", "Latn"):
            transliterate = False

        sent = self._punc_norm(sent)
        sent = self._normalize(sent)

        if iso_lang == "en":
            processed = " ".join(
                self._en_tok.tokenize(self._en_norm.normalize(sent.strip()), escape=False)
            )
        else:
            processed = self._indic_tokenize_transliterate(sent, normalizer, iso_lang, transliterate)

        processed = processed.strip()
        if not is_target:
            return f"{src_lang} {tgt_lang} {processed}"
        return processed

    def _postprocess(self, sent: str, lang: str, entity_map: dict[str, str]) -> str:
        if isinstance(sent, (tuple, list)):
            sent = sent[0]

        lang_code, script_code = lang.split("_", 1)
        iso_lang = self._flores_codes.get(lang, "hi")

        if script_code in ("Arab", "Aran"):
            sent = (
                sent.replace(" ؟", "؟")
                .replace(" ۔", "۔")
                .replace(" ،", "،")
                .replace("ٮ۪", "ؠ")
            )
        for key, val in entity_map.items():
            sent = sent.replace(key, val)

        if lang == "eng_Latn":
            return self._en_detok.detokenize(sent.split(" "))
        translated = self._xliterator.transliterate(sent, "hi", iso_lang)
        return indic_detokenize.trivial_detokenize(translated, iso_lang)

    # ---------------------------- public API --------------------------------
    def preprocess_batch(self, batch, src_lang, tgt_lang=None, is_target=False):
        normalizer = None
        if src_lang != "eng_Latn":
            iso_code = self._flores_codes.get(src_lang, "hi")
            normalizer = IndicNormalizerFactory().get_normalizer(iso_code)
        return [
            self._preprocess(s, src_lang, tgt_lang, normalizer, is_target)
            for s in batch
        ]

    def postprocess_batch(self, sents, lang="hin_Deva", num_return_sequences=1):
        num_inputs = len(sents) // max(1, num_return_sequences)
        maps = []
        for _ in range(num_inputs):
            maps.append(self._placeholder_maps.pop(0) if self._placeholder_maps else {})

        results = []
        for i, sent in enumerate(sents):
            idx = i // max(1, num_return_sequences)
            current = maps[idx % len(maps)] if maps else {}
            results.append(self._postprocess(sent, lang, current))

        self._placeholder_maps.clear()
        return results