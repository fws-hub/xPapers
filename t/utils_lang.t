use strict;
use warnings;
use utf8;
use Test::More;

use xPapers::Utils::Lang qw/ hasLang isLang getSuggestion checkLang /;

for (qw/bona fide priori posteriori modus ponens ad hominem infinitum explanandum explanans desiderata/) {
    my ($allf, $fcount, $allr, $rcount ) = checkLang( ($_) );
    ok( $allr, $_ );
}

ok( isLang("A totally English title") );

ok( hasLang("A bona fide English title") );

ok( hasLang("A totally English title") );

ok( !isLang("A bona fide English title") );

ok( !hasLang("K. W. J Keulartz, Romantisch verlangen of reformatorisch elan? De visie van Jos de Mul op Wilhelm Dilthey") );

ok( !hasLang("F. W. J. Keulartz, J. A. A. Swart & der Windvant, H. J., Natuurbeheerspraktijken en natuurbeleid"));

ok( !hasLang( "Sistema e trasgressione : logica ed analogia in Rosenzweig, Benjamin e Levinas" ) );

ok( !hasLang( " La crítica de Orayen a los lógicos relevantistas y el silogismo disyuntivo
La presente nota comenta algunos puntos de la crítica al relevantismo que constituye el capítulo V (págªs 217-62) del libro de Raúl Orayen Lógica, significado y ontología (UNAM, 1989). Por razones de espacio, me centro casi exclusivamente en el debate sobre el silogismo disyuntivo. Antes, abordo un problema metodológico general acerca de las «intuiciones», en torno a un género de argumento que usan --aunque con fines opuestos-- tanto los adalides del relevantismo cuanto Orayen en su crítica. Como conclusión de la lectura de Orayen, me preguntao si no cabe una reapreciación de la lógica relevante. Orayen también abre una perspectiva al mismo sistema E que yo juzgo el mejor de los propuestos por los relevantistas. Coincido en suma con Orayen en mi escepticismo ante los preceptos relevantistas, mas creo que, aunque sea por motivos erróneos, han encontrado algo valioso. Y algo que tiene que ver con lo que buscaban --muchas cosas tienen que ver, al fin y al cabo. Algo que se refiere a la relación de deducibilidad y a la manera de seguirle la pista. Mas ¿es compatible ese género de rehabilitación con la filosofía de la lógica que profesa Raúl Orayen?
"));

ok( !hasLang( 'Índices de impacto de las revistas españolas de Humanidades a partir del análisis de las revistas mejor valoradas por los pares'));

ok( !hasLang( "Dialéctica, lógica y formalización: de Hegel a la filosofía analítica" ));

ok( !hasLang( "Cuatro obras de Mauricio Beuchot" ));

ok( !hasLang( "Reseñas de: Newton C.A. da Costa, Lógica indutiva e probabilidade; Enrique Villanueva, Lenguaje y privacidad; J.J. Acero, Filosofía y análisis del lenguaje" ));

ok( !hasLang( "Semántica veredictiva y lógica infinivalente" ) );

ok( !hasLang( "Reseña de: Manuel Atienza y Juan Ruiz Manero, Las piezas del derecho: Teoría de los enunciados jurídicos" ));

ok( !hasLang("Анализ и обобщение метода лроверки логических формул диаграммами веннч") );
ok( !hasLang("Теория отбоошенных высказываний. II") );
ok( hasLang(
        "Max webers wertfreiheitspostulat und die naturalistische begründung Von normen",
        "Max Weber's postulate of value-neutrality and the naturalistic justification of norms. The relationship between facts and values is an essential problem in philosophy, political science and sociology. Usually it is held that there is a wide gap between what is and what ought to be, the nature of which, however, is far from clear. My purpose is to elucidate this relationship by analyzing some well-known articles of Max Weber."
    ) 
);

ok( !isLang(
        "Max webers wertfreiheitspostulat und die naturalistische begründung Von normen",
        "Max Weber's postulate of value-neutrality and the naturalistic justification of norms. The relationship between facts and values is an essential problem in philosophy, political science and sociology. Usually it is held that there is a wide gap between what is and what ought to be, the nature of which, however, is far from clear. My purpose is to elucidate this relationship by analyzing some well-known articles of Max Weber."
    ) 
);
ok( !isLang( 'ofthe one two three four' ) );

is( getSuggestion( 'Noûsq' ), 'Noûs' );

done_testing;


