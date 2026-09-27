"""Build the original bilingual curriculum from reviewed source records. No online service is used."""
import json
import re
from collections import Counter
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / 'scripts'
content = json.loads((source / 'curriculum-core.json').read_text())
content['references'].extend(json.loads((source / 'curriculum-extra-references.json').read_text()))
english_rows = [line.split('|') for line in (source / 'curriculum-expansion.txt').read_text().splitlines() if line.strip() and not line.startswith(('#', '@'))]
chinese_rows = [line.split('|') for line in (source / 'curriculum-chinese.txt').read_text().splitlines() if line.strip() and not line.startswith('#')]
assert len(english_rows) == len(chinese_rows) == 540
assert all(len(row) == 3 for row in chinese_rows)
translations = {}
for english, chinese in zip(english_rows, chinese_rows):
    for en, zh in zip(english[2:], chinese):
        if en in translations: assert translations[en] == zh
        translations[en] = zh
def bilingual(en, zh=None):
    if zh is None:
        zh = translations[en]
    return {'en': en, 'zhHans': zh}

for lesson in content['lessons']:
    simplified = json.loads((source / 'curriculum-simplifications.json').read_text())
    for section in lesson['sections']:
        if section['id'] in simplified: section['body'] = simplified[section['id']]
    lesson['keyIdea'] = lesson['sections'][0]['body']
    for i, question in enumerate(lesson['questions']):
        section = lesson['sections'][i // 2]
        question['contextSectionID'] = section['id']
        question['context'] = section['example']
        question['explanation'] = section['body'] if i % 2 == 0 else {language: section['example'][language] + ' ' + section['body'][language] for language in ['en', 'zhHans']}

rows = []
for line in (source / 'curriculum-expansion.txt').read_text().splitlines():
    if not line.strip() or line.startswith('#'): continue
    if line.startswith('@'):
        level, track, references = line[1:].split('|')
    else:
        fields = line.split('|')
        assert len(fields) == 5, fields
        rows.append((level, track, references.split(','), fields))
assert len(rows) == 540
assert all(count == 36 for count in Counter((r[0], r[1]) for r in rows).values())
for index, (level, track, references, fields) in enumerate(rows):
    title, title_zh, definition, example, boundary = fields
    slug = re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')
    lesson_id = f'course-expanded-{level}-{slug}'
    sections = [
        {'id': f'{lesson_id}-concept', 'title': bilingual('The concept', '概念是什么'), 'body': bilingual(definition), 'symbol': 'lightbulb', 'example': None},
        {'id': f'{lesson_id}-application', 'title': bilingual('A practical application', '实际应用'), 'body': bilingual(example), 'symbol': 'sparkles', 'example': bilingual(example)},
        {'id': f'{lesson_id}-boundary', 'title': bilingual('What to check', '使用时注意什么'), 'body': bilingual(boundary), 'symbol': 'checkmark.shield', 'example': None}
    ]
    group_start = index // 3 * 3
    alternatives = [rows[j][3] for j in range(group_start, group_start + 3) if j != index]
    question_specs = [
        (f'What does {title.lower()} mean?', f'“{title_zh}”的含义是什么？', definition, [a[2] for a in alternatives], definition, 0),
        (f'What needs attention when using {title.lower()} in this example?', f'在本题例子中使用“{title_zh}”时，应注意什么？', boundary, [a[4] for a in alternatives], example + ' ' + boundary, 2),
        ('Which concept is most directly demonstrated by the example?', '本题例子最直接体现了哪个概念？', title, [a[0] for a in alternatives], definition + ' ' + example, 1)
    ]
    questions = []
    for qi, (prompt, prompt_zh, correct, wrong, explanation, section_index) in enumerate(question_specs):
        choices = [correct] + wrong
        correct_index = (index + qi) % 3
        choices = choices[-correct_index:] + choices[:-correct_index] if correct_index else choices
        if qi == 2:
            title_map = {a[0]: a[1] for a in [fields] + alternatives}
            choice_texts = [bilingual(choice, title_map[choice]) for choice in choices]
            explanation_text = {'en': explanation, 'zhHans': bilingual(definition)['zhHans'] + ' ' + bilingual(example)['zhHans']}
        else:
            choice_texts = [bilingual(choice) for choice in choices]
            explanation_text = bilingual(definition) if qi == 0 else {'en': explanation, 'zhHans': bilingual(example)['zhHans'] + ' ' + bilingual(boundary)['zhHans']}
        questions.append({'id': f'{lesson_id}-question-{qi+1}', 'contextSectionID': sections[section_index]['id'], 'context': bilingual(example), 'prompt': bilingual(prompt, prompt_zh), 'choices': choice_texts, 'correctIndex': correct_index, 'explanation': explanation_text})
    if track == 'responsibleAI': references = list(dict.fromkeys(references + ['aima-ethics']))
    extra_by_title = {
        'Parameter-efficient adaptation': 'lora', 'Full fine-tuning': 'lora',
        'Model distillation': 'distillation', 'Model quantization': 'quantization',
        'Instruction tuning': 'instruction-tuning', 'Preference-based adaptation': 'human-feedback',
        'Prompt injection': 'indirect-injection', 'Prompt-injection boundaries': 'indirect-injection',
        'Untrusted retrieved content': 'indirect-injection', 'Red-team scenarios': 'indirect-injection',
        'Causal questions': 'aima-causal', 'Counterfactual reasoning': 'aima-causal',
        'Confounding factors': 'aima-causal', 'Controlled comparisons': 'aima-causal',
        'Constraint propagation': 'aima-constraint-propagation', 'Local search': 'aima-constraint-propagation',
        'Camera sensors': 'aima-robotics', 'Microphone sensors': 'aima-robotics', 'Distance sensors': 'aima-robotics',
        'Model parameters': 'deep-ml-basics', 'Dataset scope': 'deep-ml-basics', 'Covariate shift': 'deep-ml-basics',
        'Translation cache identity': 'apple-translation', 'Out-of-order responses': 'apple-translation', 'Partial translation failure': 'apple-translation',
        'Trial transparency': 'apple-subscriptions', 'Developer and public entitlements': 'apple-subscriptions'
    }
    if title in extra_by_title: references.append(extra_by_title[title])
    content['lessons'].append({'id': lesson_id, 'order': 100 + index, 'track': track, 'level': level, 'title': bilingual(title, title_zh), 'summary': bilingual('Concept · Real application · Practical boundary', '概念 · 实际应用 · 使用边界'), 'keyIdea': bilingual(definition), 'sections': sections, 'questions': questions, 'estimatedMinutes': 5, 'isFree': False, 'referenceIDs': references})

content['schemaVersion'] = 3
assert len(content['lessons']) == 600
assert len(set(l['id'] for l in content['lessons'])) == 600
for lesson in content['lessons']:
    assert all(r in {ref['id'] for ref in content['references']} for r in lesson['referenceIDs'])
    assert all(q['context'] and q['contextSectionID'] in {s['id'] for s in lesson['sections']} for q in lesson['questions'])
    assert all(len(set(c['en'] for c in q['choices'])) == 3 for q in lesson['questions'])
output = root / 'AIFrontier/Resources/Curriculum.json'
output.write_text(json.dumps(content, ensure_ascii=False, indent=2) + '\n')
print(f'{len(content["lessons"])} lessons; {sum(len(l["sections"]) for l in content["lessons"])} explanation sections; {sum(len(l["questions"]) for l in content["lessons"])} questions')
