# Copilot Instructions

## Parameters (Toggle Settings)

- maintain_project_context_file: true          # Agentic is responsible for keeping the context file up to date.
- allow_create_new_context_file: true          # enabled just for initial, you should disable this when youre done
- allow_additional_docs: false                 # No extra docs or markdown allowed, unless explicitly requested.
- include_WIP_in_context: false                # no wip for now, i will explicitly prompt our next task
- auto_sync_on_merge: true                     # Update context after significant code merges or refactors.
- ask_user_if_unsure: true                     # If unsure about context, always ask the user before assuming.
- context_file_path: ".github/project-context.md"   # Path to the single, living project context file.

---

## Main Agentic Instructions

1. **Project Context Ownership:**  
   - You are responsible for maintaining the project context in the file specified by `context_file_path`.
   - If the file does not exist and `allow_create_new_context_file` is true, create it with the standard structure (see below).

2. **Context File Management:**  
   - Always keep the context file up to date.  
   - Never use placeholders—only write what is true and current.
   - Reference the context file before generating, reviewing, or refactoring any code.

3. **Section Controls:**  
   - If `include_WIP_in_context` is true, ensure a "Work In Progress" section exists in the context file and keep it updated.
   - If `include_intentionally_left_out` is true, manage an "Intentionally Left Out" section in the context file.
   - Otherwise, exclude those sections.

4. **Documentation & Files:**  
   - Do not create or modify any documentation, markdown, or extra files except the project context file, unless `allow_additional_docs` is true.

5. **Sync and Communication:**  
   - If `auto_sync_on_merge` is true, always update the context file after major code merges or refactorings.
   - If `ask_user_if_unsure` is true and you lack context or clarity, stop and prompt the user for information before continuing.

6. **Best Practices:**  
   - Always keep the context file minimal, easy to scan, and up to date.
   - Maintain a clean, logical order: Project summary, features, NFR/design language, WIP (optional), current state, and notes.
   - Avoid bloat or repetition.

---

# End of instructions