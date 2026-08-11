# TodoMate Architecture Workbench

이 디렉터리는 TodoMate의 현재 구조를 source evidence와 함께 탐색하는 Workbench다.

- `current/*.md`: Agent가 코드 변경과 함께 유지하는 canonical Architecture Markdown
- `resolved.generated.json`: Markdown에서 생성한 resolved read model
- `site/index.html`: resolved model을 포함한 offline interactive explorer

JSON과 HTML은 파생물이며 직접 편집하지 않는다. 검증·재생성 명령:

```bash
python3 agent-skills/architecture-workbench/scripts/architecture_workbench.py validate --root .
python3 agent-skills/architecture-workbench/scripts/architecture_workbench.py build --root .
```

`verifiedGitCommit`은 source evidence를 마지막으로 직접 대조한 commit이다. validator는 그 commit
이후 cited source가 바뀌었는지와 현재 path/symbol의 존재를 검사한다. 의미 판단과 current 문서
갱신은 Agent가 소유한다.
