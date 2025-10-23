#!/bin/bash
# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    run_tests                                          :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: sdestann <sdestann@student.42perpignan.    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/10/13 14:07:12 by sdestann          #+#    #+#              #
#    Updated: 2025/10/14 20:08:19 by sdestann         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

set -e

echo "🚀 Lancement des tests Famine..."

cd /workspace/workspace || cd /workspace

if [ ! -f ./Famine ]; then
  echo "❌ Le binaire Famine n'existe pas. Compile-le d'abord avec 'make -C workspace'."
  exit 1
fi

echo "🔎 Exécution de Famine sur /tmp/test et /tmp/test2..."
./Famine || echo "⚠️ Famine terminé avec un code non nul (vérifie analysis_mode)."

echo ""
echo "🧪 Vérification de la signature dans /tmp/test/sample..."
if strings /tmp/test/sample | grep -q "Famine version"; then
  echo "✅ Signature détectée dans sample !"
else
  echo "❌ Aucune signature trouvée."
fi

echo ""
echo "🏁 Fin des tests."
