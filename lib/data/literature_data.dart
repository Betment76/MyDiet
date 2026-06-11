// Книги Ковалькова, использованные в приложении, и раздел «Используемая литература»
// из «Победа над весом».

class LiteratureEntry {
  final int number;
  final String citation;

  const LiteratureEntry({required this.number, required this.citation});
}

/// Книги А.В. Ковалькова — источники методик приложения.
const List<String> kovalkovAppSources = [
  'Ковальков А.В. Минус размер. Новая безопасная экспресс-диета. – М.: Эксмо, 2015.',
  'Ковальков А.В. Диета для гурманов. План питания от доктора Ковалькова. – М.: Эксмо, 2015.',
  'Ковальков А.В. Худеем интересно. Рецепты вкусной и здоровой жизни. – М.: Эксмо, 2014.',
  'Ковальков А.В. Как худеют настоящие мужчины. Клиническая диета доктора Ковалькова. – М.: Эксмо, 2021.',
  'Ковальков А.В. Методика доктора Ковалькова. Победа над весом. – М.: Эксмо, 2011.',
];

/// Раздел «Используемая литература», книга «Победа над весом».
const List<String> _victoryBibliographyCitations = [
  'Стоянова Е.С. Похудеть. – М.: Кристина, 2003.',
  'Барбара Эдельштейн. Диета для людей с пониженным обменом.',
  'Дж. Райли. Как прекратить переедать и начать жить.',
  'Мак-Мюррей У. Обмен веществ у человека. – М., 1980.',
  'Теппермен Дж., Теппермен Х. Физиология обмена веществ и эндокринной системы. – М.: Мир, 1989.',
  'Марри Р., Греннер Д., Мейес П., Родуэлл В. Биохимия человека. – М.: Мир, 1993.',
  'Михаил Гинзбург. Как победить избыточный вес. – Самара.: Парус, 1999.',
  'Минвалеев Р.С. Похудеть без вреда. Очерки прикладной физиологии. – СПб: Питер, 2003.',
  'Чурилов Л.П. Новое о патогенезе ожирения // Мир медицины. М. 2001. № 3–4.',
  'Фалеев А.В. Что поможет похудению? Бизнес на лишнем весе, или как нас обманывают. – Р-на-Д.: МарТ, 2006 г.',
  'Уголев А.М. Пищеварение и его приспособительная эволюция. – М., 1961.',
  'Уголев А.М. Пристеночное (контактное) пищеварение. – М.—Л., 1963.',
  'Уголев А.М. Физиология и патология пристеночного (контактного) пищеварения. – Л., 1967.',
  'Уголев А.М. Мембранное пищеварение. Полисубстратные процессы, организация и регуляция. – Л., 1972.',
  'Уголев А.М. Физиология мембранного (пристеночного) пищеварения (совместно с другими), в кн.: Физиология пищеварения. – Л., 1974.',
  'Уголев А.М. Эволюция пищеварения и принципы эволюции функций: Элементы современного функционализма. – Л., Наука, 1985.',
  'Уголев А.М. Естественные технологии биологических систем. – Л.: Наука, 1987.',
  'Уголев А.М. Теория адекватного питания и трофология. – Санкт-Петербург: Наука, 1991.',
  'Ермолаев М.В., Ильичева Л.П. Биологическая химия. – М.: Медицина, 1989.',
  'Каркищенко Н.Н. Клиническая и экологическая фармакология в терминах, понятиях. – М.: Медгиз, 1995. С. 304.',
  'Козупица Г.С. Взаимосвязь аэробной физической работоспособности с составом тела. – Актуальные проблемы спортивной медицины // Труды Самарской областной федерации спортивной медицины. Самара, 1998, Т. 1. С. 34–35.',
  'Комаров Ф.А., Рапопорт С.И. Хронобиология и хронономедицина. – М.: Триада-Х, 2000. С. 488.',
  'Авцин А.П., Жаворонков А.А., Риш М.А., Строчкова М.С. Микроэлементозы человека: этиология, классификация, органопатология. – М.: Медицина, 1991. С. 496.',
  'Агаджанян Н.А. Адаптация и резервы организма. – М.: ФиС, 1983. – С. 176.',
  'Базисная и клиническая фармакология // Пер. с англ. под ред. Бертрама Г. Катцунга. – М.: Бином, 1998. – Т. 1, 2.',
  'Бобков Ю.Г., Виноградов В.М., Лосев С.С., Смирнов А.В. Фармакологическая коррекция утомления. – М.: Медицина, 1984. С. 208.',
  'Word Health Organization: Preventing and Managing the Global Epidemic of Obesity. Report of the WHO Consultation on Obesity. WHO, 1998.',
  'Flegal K.M., Carroll M.D., Kuczmarski R.J., Johnson C.L.: Overweight and obesity in the United States: prevalence and trends, 1960–1994. Int J. Obesity 1998;22:39–47.',
  'Mokdad A.H., Bowman B.A., Ford E.S., Vinicor F., Marks J.S., Koplan J.P.: The continuing epidemics of obesity and diabetes in the United States. JAMA 2001;286:1195–1200.',
  'Must A., Spadano J., Coakley E., Field A., Colditz G., Dietz W.: The disease burden associated with overweight and obesity. JAMA 1999;282:1523–1529.',
  'National Task Force on the Prevention and Treatment of Obesity: Overweight, obesity, and health risk. Arch. Intern. Med. 2000;160:898–904.',
  'The Practical Guide to the Identification, Evaluation and Treatment of Overweight and Obesity in Adults. NIH Publication Number 00–4084, Oct. 2000.',
  'Executive Summary of the Third Report of the National Cholesterol Education Program (NCEP) Expert Panel on Detection, Evaluation, and Treatment of High Blood Cholesterol in Adults (Adult Treatment Panel III). JAMA 2001, 285: 2486–2497.',
  'Position Statement: Screening for Diabetes. American Diabetes Association Clinical Practice Recommendations 2001. Diabetes Care 24 (Supplement 1).',
  "Findling J.W., Raff H.: Newer diagnostic techniques and problems in Cushing's Disease. Endocrinol. Metabol. Clin. North Am. 1999,28(1):191–210.",
  'Foster GD, Johnson C: Facilitating health and selfesteem among obese patients. Prim Psychiatr 1998, 5:89–95.',
  "Foster GD, Wadden TA, Vogt RA, Brewer G: What is a reasonable weight loss? Patient's expectations and evaluations of obesity treatment outcomes. J Consulting and Clin Psychol 1997, 65: 79–85.",
  'Stuncard AJ: Talking with patients. In: Stuncard AJ and Wadden TA (eds): Obesity: Theory and Therapy. 2nd ed. New York, Raven Press; 1993, pp. 355–363.',
  'Stuncard AJ, Sobal J: Psychosocial consequences of obesity. In: Brownell KD and Fairburn CG (eds): Eating Disorders and Obesity: A Comprehensive Handbook. New York, Guilford Press; 1995, pp. 417–421.',
  'Wadden TA, Foster GD: Behavioral treatment of obesity. In: Jensen M (ed): Medical Clinics of North America. 2000, 84:2, 441–461.',
  'Wadden TA, Wingate BJ: Compassionate treatment of the obese individual. In: Brownell KD and Fairburn CG (eds): Eating Disorders and Obesity: A Comprehensive Handbook. New York, Guilford Press; 1995, pp. 564–571.',
];

/// Полный список для экрана «Используемая литература».
final List<LiteratureEntry> appLiterature = [
  for (var i = 0; i < kovalkovAppSources.length; i++)
    LiteratureEntry(number: i + 1, citation: kovalkovAppSources[i]),
  for (var i = 0; i < _victoryBibliographyCitations.length; i++)
    LiteratureEntry(
      number: kovalkovAppSources.length + i + 1,
      citation: _victoryBibliographyCitations[i],
    ),
];