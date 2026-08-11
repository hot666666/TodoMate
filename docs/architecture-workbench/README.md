# TodoMate Architecture Workbench

이 디렉터리는 TodoMate의 현재 구조를 source evidence와 함께 탐색하는 Workbench다.

- `current/*.md`: Agent가 코드 변경과 함께 유지하는 canonical Architecture Markdown
- `resolved.generated.json`: Markdown에서 생성한 resolved read model
- `site/index.html`: resolved model을 포함한 offline interactive explorer
- `feedback/open/*.md`: stable ID와 verified commit을 보존하는 열린 질문·개선 요청
- `feedback/resolved/*.md`: 답변·근거와 함께 종료된 feedback
- `proposed/<proposal-id>/`: feedback에 연결된 To-Be snapshot과 승인 전 replacement set

JSON과 HTML은 파생물이며 직접 편집하지 않는다. 검증·재생성 명령:

```bash
python3 agent-skills/architecture-workbench/scripts/architecture_workbench.py validate --root .
python3 agent-skills/architecture-workbench/scripts/architecture_workbench.py build --root .
```

정적 HTML의 Inspector에서 feedback JSON을 내려받을 수 있다. 로컬 저장이 필요하면 다음처럼
loopback 전용 서버를 실행한다.

```bash
python3 agent-skills/architecture-workbench/scripts/feedback_server.py --root . --port 8765
```

서버는 `127.0.0.1`에만 bind하고 generated index, health, feedback 저장 endpoint만 제공한다.
feedback은 production source 변경 승인이 아니며, Agent 답변 또는 current Markdown correction은
source evidence를 다시 검토한 뒤 기록한다.

코드 변경 요청은 `proposed/`에서만 preview하며, 존재하거나 렌더링되었다는 이유로
`current/` 또는 product source를 변경하지 않는다. 정확한 proposal digest와 base commit에 대한
현재 turn의 명시적 승인을 별도 approval JSON으로 기록한 경우에만 code와 current Markdown을
하나의 apply set으로 적용한다. 상세 계약과 명령은 Skill의 `references/proposal-contract.md`를 따른다.

`verifiedGitCommit`은 source evidence를 마지막으로 직접 대조한 commit이다. validator는 그 commit
이후 cited source가 바뀌었는지와 현재 path/symbol의 존재를 검사한다. 의미 판단과 current 문서
갱신은 Agent가 소유한다.
