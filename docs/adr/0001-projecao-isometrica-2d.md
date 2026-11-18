# Projeção isométrica 2D sobre simulação ortogonal

DeadWorks usa sprites 2D e uma câmera isométrica fixa para dar leitura espacial à sobrevivência e à fábrica sem exigir uma cena 3D. As regras continuam em coordenadas ortogonais, enquanto a apresentação converte posição, direção e clique do mouse. Isso preserva os testes headless e o custo baixo de produção, mas exige conversão explícita na entrada e ordenação visual por profundidade.
