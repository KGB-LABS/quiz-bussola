# Desafio da Bússola

Quiz de 5 perguntas para os escoteiros e painel dos chefes. Página estática (GitHub Pages), separada do site.

- `index.html`: tela inicial (nome e patrulha) + quiz, sem login. O botão **Começar** só acende quando o chefe libera o desafio.
- `painel.html`: botão **Liberar / Encerrar desafio** e quem acertou tudo primeiro (login de admin do site).
- `supabase/quiz_bussola_liberacao.sql`: tabela `quiz_bussola_estado`, função `quiz_bussola_liberar` (só admin/master) e trigger que recusa envios com o desafio fechado.

O gabarito e a correção ficam só no Supabase (função `quiz_bussola_enviar`). A chave usada nas páginas é a publicável, feita para ficar no navegador.
