import '../models/user_badge.dart';

class BadgeDefinitions {
  static final List<UserBadge> marathonerMilestones = [
    UserBadge(id: "mbase", title: "Marathoner", imagePath: "assets/images/marathoner_base.png", iconLabel: "1d", targetHours: 24, nextId: "mbronze"),
    UserBadge(id: "mbronze", title: "Marathoner", imagePath: "assets/images/marathoner_bronze.png", iconLabel: "3d", targetHours: 72, nextId: "msilver"),
    UserBadge(id: "msilver", title: "Marathoner", imagePath: "assets/images/marathoner_silver.png", iconLabel: "10d", targetHours: 240, nextId: "mgold"),
    UserBadge(id: "mgold", title: "Marathoner", imagePath: "assets/images/marathoner_gold.png", iconLabel: "20d", targetHours: 480, nextId: "mdiamond"),
    UserBadge(id: "mdiamond", title: "Marathoner", imagePath: "assets/images/marathoner_diamond.png", iconLabel: "100d", targetHours: 2400, nextId: null),
  ];

  static final List<UserBadge> obsessionMilestones = [
    UserBadge(id: "pbase", title: "Pure Obsession", imagePath: "assets/images/pure_obsession_base.png", iconLabel: "1h", targetHours: 1, nextId: "pbronze"),
    UserBadge(id: "pbronze", title: "Pure Obsession", imagePath: "assets/images/pure_obsession_bronze.png", iconLabel: "3h", targetHours: 3, nextId: "psilver"),
    UserBadge(id: "psilver", title: "Pure Obsession", imagePath: "assets/images/pure_obsession_silver.png", iconLabel: "8h", targetHours: 8, nextId: "pgold"),
    UserBadge(id: "pgold", title: "Pure Obsession", imagePath: "assets/images/pure_obsession_gold.png", iconLabel: "14h", targetHours: 14, nextId: "pdiamond"),
    UserBadge(id: "pdiamond", title: "Pure Obsession", imagePath: "assets/images/pure_obsession_diamond.png", iconLabel: "20h", targetHours: 20, nextId: null),
  ];

  static final List<UserBadge> weekendMilestones = [
    UserBadge(id: "wbase", title: "Weekend Warrior", imagePath: "assets/images/weekend_warrior_base.png", iconLabel: "3h", targetHours: 3, nextId: "wbronze"),
    UserBadge(id: "wbronze", title: "Weekend Warrior", imagePath: "assets/images/weekend_warrior_bronze.png", iconLabel: "10h", targetHours: 10, nextId: "wsilver"),
    UserBadge(id: "wsilver", title: "Weekend Warrior", imagePath: "assets/images/weekend_warrior_silver.png", iconLabel: "15h", targetHours: 15, nextId: "wgold"),
    UserBadge(id: "wgold", title: "Weekend Warrior", imagePath: "assets/images/weekend_warrior_gold.png", iconLabel: "24h", targetHours: 24, nextId: "wdiamond"),
    UserBadge(id: "wdiamond", title: "Weekend Warrior", imagePath: "assets/images/weekend_warrior_diamond.png", iconLabel: "48h", targetHours: 48, nextId: null),
  ];

  static final List<UserBadge> streakMilestones = [
    UserBadge(id: "sbase", title: "Streak", imagePath: "assets/images/streak_base.png", iconLabel: "7d", targetHours: 7, nextId: "sbronze"),
    UserBadge(id: "sbronze", title: "Streak", imagePath: "assets/images/streak_bronze.png", iconLabel: "10d", targetHours: 10, nextId: "ssilver"),
    UserBadge(id: "ssilver", title: "Streak", imagePath: "assets/images/streak_silver.png", iconLabel: "20d", targetHours: 20, nextId: "sgold"),
    UserBadge(id: "sgold", title: "Streak", imagePath: "assets/images/streak_gold.png", iconLabel: "50d", targetHours: 50, nextId: "sdiamond"),
    UserBadge(id: "sdiamond", title: "Streak", imagePath: "assets/images/streak_diamond.png", iconLabel: "100d", targetHours: 100, nextId: null),
  ];

  static final List<UserBadge> completionistMilestones = [
    UserBadge(id: "tpbase", title: "The Perfectionist", imagePath: "assets/images/the_completionist_base.png", iconLabel: "1 Series", targetHours: 1, nextId: "tpbronze"),
    UserBadge(id: "tpbronze", title: "The Perfectionist", imagePath: "assets/images/the_completionist_bronze.png", iconLabel: "3 Series", targetHours: 3, nextId: "tpsilver"),
    UserBadge(id: "tpsilver", title: "The Perfectionist", imagePath: "assets/images/the_completionist_silver.png", iconLabel: "10 Series", targetHours: 10, nextId: "tpgold"),
    UserBadge(id: "tpgold", title: "The Perfectionist", imagePath: "assets/images/the_completionist_gold.png", iconLabel: "20 Series", targetHours: 20, nextId: "tpdiamond"),
    UserBadge(id: "tpdiamond", title: "The Perfectionist", imagePath: "assets/images/the_completionist_diamond.png", iconLabel: "50 Series", targetHours: 50, nextId: null),
  ];

  static final List<UserBadge> nightOwlMilestones = [
    UserBadge(id: "nobase", title: "The Night Owl", imagePath: "assets/images/the_night_owl_base.png", iconLabel: "1h", targetHours: 1, nextId: "nobronze"),
    UserBadge(id: "nobronze", title: "The Night Owl", imagePath: "assets/images/the_night_owl_bronze.png", iconLabel: "5h", targetHours: 5, nextId: "nosilver"),
    UserBadge(id: "nosilver", title: "The Night Owl", imagePath: "assets/images/the_night_owl_silver.png", iconLabel: "15h", targetHours: 15, nextId: "nogold"),
    UserBadge(id: "nogold", title: "The Night Owl", imagePath: "assets/images/the_night_owl_gold.png", iconLabel: "30h", targetHours: 30, nextId: "nodiamond"),
    UserBadge(id: "nodiamond", title: "The Night Owl", imagePath: "assets/images/the_night_owl_diamond.png", iconLabel: "50h", targetHours: 50, nextId: null),
  ];

  static final List<UserBadge> genreMilestones = [
    UserBadge(id: "gbase", title: "Genre Explorer", imagePath: "assets/images/genre_explorer_base.png", iconLabel: "1 Genres", targetHours: 1, nextId: "gbronze"),
    UserBadge(id: "gbronze", title: "Genre Explorer", imagePath: "assets/images/genre_explorer_bronze.png", iconLabel: "3 Genres", targetHours: 3, nextId: "gsilver"),
    UserBadge(id: "gsilver", title: "Genre Explorer", imagePath: "assets/images/genre_explorer_silver.png", iconLabel: "4 Genres", targetHours: 4, nextId: "ggold"),
    UserBadge(id: "ggold", title: "Genre Explorer", imagePath: "assets/images/genre_explorer_gold.png", iconLabel: "6 Genres", targetHours: 6, nextId: "gdiamond"),
    UserBadge(id: "gdiamond", title: "Genre Explorer", imagePath: "assets/images/genre_explorer_diamond.png", iconLabel: "8 Genres", targetHours: 8, nextId: null),
  ];
  
  static List<UserBadge> get allMilestones => [
    ...marathonerMilestones,
    ...obsessionMilestones,
    ...weekendMilestones,
    ...streakMilestones,
    ...completionistMilestones,
    ...nightOwlMilestones,
    ...genreMilestones,
  ];
}