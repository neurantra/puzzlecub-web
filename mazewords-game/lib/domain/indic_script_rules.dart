// Generated from tools/languages/script-rules.json. Keep build/runtime tile rules aligned.
class IndicScriptRules {
  const IndicScriptRules(
    this.bases,
    this.marks,
    this.virama,
    this.allowTerminalVirama,
  );
  final String bases, marks;
  final int virama;
  final bool allowTerminalVirama;
}

const indicScriptRules = <String, IndicScriptRules>{
  'te': IndicScriptRules(
    'అఆఇఈఉఊఋఌఎఏఐఒఓఔకఖగఘఙచఛజఝఞటఠడఢణతథదధనపఫబభమయరఱలళఴవశషసహౘౙౚౝౠౡ',
    'ఀఁంఃఄ఼ాిీుూృౄెేైొోౌ్ౕౖౢౣ',
    3149,
    false,
  ),
  'kn': IndicScriptRules(
    'ಅಆಇಈಉಊಋಌಎಏಐಒಓಔಕಖಗಘಙಚಛಜಝಞಟಠಡಢಣತಥದಧನಪಫಬಭಮಯರಱಲಳವಶಷಸಹೝೞೠೡ',
    'ಁಂಃ಼ಾಿೀುೂೃೄೆೇೈೊೋೌ್ೕೖೢೣೳ',
    3277,
    false,
  ),
  'ml': IndicScriptRules(
    'ഄഅആഇഈഉഊഋഌഎഏഐഒഓഔകഖഗഘങചഛജഝഞടഠഡഢണതഥദധനഩപഫബഭമയരറലളഴവശഷസഹഺൔൕൖൟൠൡൺൻർൽൾൿ',
    'ഀഁംഃ഻഼ാിീുൂൃൄെേൈൊോൌ്ൗൢൣ',
    3405,
    true,
  ),
  'gu': IndicScriptRules(
    'અઆઇઈઉઊઋઌએઐઓઔકખગઘઙચછજઝઞટઠડઢણતથદધનપફબભમયરલળવશષસહૠૡૹ',
    'ઁંઃ઼ાિીુૂૃૄૅેૈૉોૌ્ૢૣૺૻૼ૽૾૿',
    2765,
    false,
  ),
  'pa': IndicScriptRules(
    'ਅਆਇਈਉਊਏਐਓਔਕਖਗਘਙਚਛਜਝਞਟਠਡਢਣਤਥਦਧਨਪਫਬਭਮਯਰਲਲ਼ਵਸ਼ਸਹਖ਼ਗ਼ਜ਼ੜਫ਼',
    'ਁਂਃ਼ਾਿੀੁੂੇੈੋੌ੍ੑੰੱੵ',
    2637,
    false,
  ),
};
