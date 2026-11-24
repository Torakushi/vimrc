" Lean 4: unicode input via \-prefixed insert mappings, same names as the
" VS Code extension. Buffer-local, loaded after lean.vim's own ftplugin.
" Typing `\` then a non-mapped key inserts `\` as is.

" Types and structures
inoremap <buffer> \x ×
inoremap <buffer> \times ×
inoremap <buffer> \oplus ⊕
inoremap <buffer> \to →
inoremap <buffer> \r →
inoremap <buffer> \l ←
inoremap <buffer> \mapsto ↦
inoremap <buffer> \fun λ
inoremap <buffer> \lam λ
inoremap <buffer> \< ⟨
inoremap <buffer> \> ⟩
inoremap <buffer> \. ·
inoremap <buffer> \circ ∘
inoremap <buffer> \comp ∘
inoremap <buffer> \Pi Π
inoremap <buffer> \Sigma Σ

" Number sets
inoremap <buffer> \N ℕ
inoremap <buffer> \Z ℤ
inoremap <buffer> \Q ℚ
inoremap <buffer> \R ℝ
inoremap <buffer> \C ℂ

" Greek letters (short + full name)
inoremap <buffer> \a α
inoremap <buffer> \alpha α
inoremap <buffer> \b β
inoremap <buffer> \beta β
inoremap <buffer> \g γ
inoremap <buffer> \gamma γ
inoremap <buffer> \d δ
inoremap <buffer> \delta δ
inoremap <buffer> \e ε
inoremap <buffer> \epsilon ε
inoremap <buffer> \s σ
inoremap <buffer> \sigma σ
inoremap <buffer> \t τ
inoremap <buffer> \tau τ
inoremap <buffer> \pi π
inoremap <buffer> \mu μ
inoremap <buffer> \phi φ
inoremap <buffer> \psi ψ
inoremap <buffer> \omega ω
inoremap <buffer> \lambda λ

" Logic
inoremap <buffer> \forall ∀
inoremap <buffer> \all ∀
inoremap <buffer> \exists ∃
inoremap <buffer> \ex ∃
inoremap <buffer> \and ∧
inoremap <buffer> \or ∨
inoremap <buffer> \not ¬
inoremap <buffer> \neg ¬
inoremap <buffer> \iff ↔
inoremap <buffer> \top ⊤
inoremap <buffer> \bot ⊥

" Comparisons and sets
inoremap <buffer> \ne ≠
inoremap <buffer> \le ≤
inoremap <buffer> \ge ≥
inoremap <buffer> \in ∈
inoremap <buffer> \notin ∉
inoremap <buffer> \sub ⊆
inoremap <buffer> \subseteq ⊆
inoremap <buffer> \ssub ⊂
inoremap <buffer> \cup ∪
inoremap <buffer> \cap ∩
inoremap <buffer> \empty ∅
inoremap <buffer> \inv ⁻¹
