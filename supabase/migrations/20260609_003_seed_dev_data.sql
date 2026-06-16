-- =============================================================================
-- Fulɓe Connect — Seed Data (Development Only)
-- =============================================================================
-- Date    : 2026-06-09
-- Purpose : Insert mock-equivalent data so the app is usable out of the box
--           in dev. Maps 1-to-1 with the previous lib/core/data/mock_*.dart
--           fixtures. DO NOT run in production.
-- Order   : 3/4 (run AFTER 001_init_schema and 002_rls_policies)
--
-- Best practices applied:
--   * data-batch-inserts   : single INSERT ... VALUES (...) per table
--   * schema-lowercase-identifiers : all identifiers in snake_case
--   * idempotent           : ON CONFLICT DO NOTHING on every insert
-- =============================================================================

-- Reusable sentinel UUIDs (deterministic for stable dev environment)
-- The first 8 chars are memorable; the rest are filler.
do $$
declare
  member_amadou        uuid := 'a0000001-0000-0000-0000-000000000001';
  member_aissatou      uuid := 'a0000002-0000-0000-0000-000000000002';
  member_ibrahima      uuid := 'a0000003-0000-0000-0000-000000000003';
  member_fatou         uuid := 'a0000004-0000-0000-0000-000000000004';
  member_ousmane       uuid := 'a0000005-0000-0000-0000-000000000005';
  member_mariama       uuid := 'a0000006-0000-0000-0000-000000000006';
  member_moussa        uuid := 'a0000007-0000-0000-0000-000000000007';
  member_aaliyah       uuid := 'a0000008-0000-0000-0000-000000000008';
begin
  ----------------------------------------------------------------------------
  -- members
  ----------------------------------------------------------------------------
  insert into public.members
    (id, full_name, profession, city, country, avatar_url, initials, is_verified, linkedin)
  values
    (member_amadou,   'Amadou Diallo',     'Senior Full-Stack Developer', 'Dakar',     'Sénégal',
       'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&q=80',
       'AD', true,  'https://linkedin.com/in/amadou-diallo'),
    (member_aissatou, 'Dr. Aïssatou Sow',  'Médecin Généraliste',         'Paris',     'France',
       'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150&h=150&fit=crop&q=80',
       'AS', true,  'https://linkedin.com/in/aissatou-sow'),
    (member_ibrahima, 'Ibrahima Barry',    'Entrepreneur Agricole',       'Conakry',   'Guinée',
       null, 'IB', false, null),
    (member_fatou,    'Fatou Barry',       'Tech Entrepreneur',           'Dakar',     'Sénégal',
       'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=150&h=150&fit=crop&q=80',
       'FB', true,  'https://linkedin.com/in/fatou-barry'),
    (member_ousmane,  'Ousmane Baldé',     'Avocat International',        'Bruxelles', 'Belgique',
       'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&q=80',
       'OB', true,  'https://linkedin.com/in/ousmane-balde'),
    (member_mariama,  'Mariama Diallo',    'Architecte & Designer',       'Milan',     'Italie',
       'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150&h=150&fit=crop&q=80',
       'MD', false, null),
    (member_moussa,   'Moussa Bah',        'Chercheur en Économie',       'Montréal',  'Canada',
       null, 'MB', false, null),
    (member_aaliyah,  'Aaliyah Sow',       'UX Designer & Cultural Liaison', 'Dakar',  'Sénégal',
       'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=150&h=150&fit=crop&q=80',
       'AS', true,  'https://linkedin.com/in/aaliyah-sow')
  on conflict (id) do nothing;

  ----------------------------------------------------------------------------
  -- member_skills (1-to-many per member)
  ----------------------------------------------------------------------------
  insert into public.member_skills (member_id, skill) values
    (member_amadou,   'Flutter'),
    (member_amadou,   'Node.js'),
    (member_amadou,   'React'),
    (member_amadou,   'PostgreSQL'),
    (member_aissatou, 'Médecine interne'),
    (member_aissatou, 'Pédiatrie'),
    (member_aissatou, 'Urgences'),
    (member_ibrahima, 'Agro-business'),
    (member_ibrahima, 'Irrigation'),
    (member_ibrahima, 'Export'),
    (member_fatou,    'FinTech'),
    (member_fatou,    'Gestion de projet'),
    (member_fatou,    'Fundraising'),
    (member_ousmane,  'Droit international'),
    (member_ousmane,  'Arbitrage'),
    (member_ousmane,  'Immigration'),
    (member_mariama,  'Architecture'),
    (member_mariama,  'Design intérieur'),
    (member_mariama,  'AutoCAD'),
    (member_moussa,   'Économétrie'),
    (member_moussa,   'Développement'),
    (member_moussa,   'Recherche'),
    (member_aaliyah,  'UX Design'),
    (member_aaliyah,  'Pulaar Translation'),
    (member_aaliyah,  'Figma'),
    (member_aaliyah,  'Cultural Research')
  on conflict do nothing;

  ----------------------------------------------------------------------------
  -- member_clusters
  ----------------------------------------------------------------------------
  insert into public.member_clusters (id, name, country, count, lat_pct, lng_pct) values
    ('b0000001-0000-0000-0000-000000000001', 'Dakar & Sénégal',  'Sénégal', 142, 0.545, 0.395),
    ('b0000002-0000-0000-0000-000000000002', 'Conakry & Guinée', 'Guinée',   86, 0.570, 0.410),
    ('b0000003-0000-0000-0000-000000000003', 'Paris & Île-de-France', 'France',  34, 0.325, 0.485),
    ('b0000004-0000-0000-0000-000000000004', 'Milan & Nord Italie', 'Italie', 12, 0.345, 0.505),
    ('b0000005-0000-0000-0000-000000000005', 'Bamako & Mali',    'Mali',     58, 0.520, 0.430)
  on conflict (id) do nothing;

  ----------------------------------------------------------------------------
  -- posts
  ----------------------------------------------------------------------------
  insert into public.posts
    (id, author_id, content, image_url, likes_count, comments_count, time_ago, created_at)
  values
    ('c0000001-0000-0000-0000-000000000001', member_mariama,
       'Incroyablement fier de présenter mon dernier projet architectural intégrant des motifs géométriques Peuls traditionnels avec des matériaux durables modernes. Les retours de la communauté sont très positifs. 🏗️✨',
       'https://images.unsplash.com/photo-1486325212027-8081e485255e?w=800&q=80',
       124, 18, 'Il y a 2h', now() - interval '2 hours'),
    ('c0000002-0000-0000-0000-000000000002', member_fatou,
       'Vient de terminer une incroyable table ronde sur l''entrepreneuriat tech en Afrique francophone. Les talents et l''innovation dans notre communauté sont vraiment inspirants ! #FulbeTech #Innovation',
       null, 89, 5, 'Il y a 5h', now() - interval '5 hours'),
    ('c0000003-0000-0000-0000-000000000003', member_aissatou,
       'Nouvelle publication sur la médecine préventive dans les communautés diasporiques. L''accès aux soins de santé reste un défi majeur. Travaillons ensemble pour créer des solutions. 🏥💚',
       'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=800&q=80',
       203, 31, 'Il y a 1j', now() - interval '1 day')
  on conflict (id) do nothing;

  ----------------------------------------------------------------------------
  -- announcements
  ----------------------------------------------------------------------------
  insert into public.announcements
    (id, chip_label, chip_icon, title, description, cta_label, cta_route, active)
  values
    ('d0000001-0000-0000-0000-000000000001',
       'Événement à venir', 'event',
       'Rencontre Annuelle de la Diaspora',
       'Rejoignez-nous à Paris pour un weekend d''échanges culturels, de networking et de célébration.',
       'RSVP maintenant', '/events', true),
    ('d0000002-0000-0000-0000-000000000002',
       'Nouvelle ressource', 'school',
       'Cours de Pulaar Niveau 2',
       'Améliorez vos compétences conversationnelles avec nos nouveaux modules interactifs.',
       'Commencer', '/learn', true)
  on conflict (id) do nothing;

  ----------------------------------------------------------------------------
  -- events
  ----------------------------------------------------------------------------
  insert into public.events
    (id, title, date, location, category, description, image_url, attendee_count, created_by)
  values
    ('e0000001-0000-0000-0000-000000000001',
       'Conférence Annuelle de la Diaspora Fulɓe',
       '2026-07-15 14:00:00+00', 'Maison de la Mutualité, Paris, France',
       'Conférence',
       'Un rassemblement de leaders d''opinion, d''entrepreneurs et d''universitaires pour discuter du rôle de la diaspora dans le codéveloppement économique et culturel.',
       'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=600&fit=crop&q=80',
       342, member_aissatou),
    ('e0000002-0000-0000-0000-000000000002',
       'Grand Festival de la Culture Peule (Fouta Toro)',
       '2026-08-05 10:00:00+00', 'Podor, Région de Saint-Louis, Sénégal',
       'Festival',
       'Célébration annuelle de la musique, de la danse, de la poésie et de l''artisanat traditionnel Peul le long du fleuve Sénégal.',
       'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=600&fit=crop&q=80',
       1250, member_ibrahima),
    ('e0000003-0000-0000-0000-000000000003',
       'Webinaire : Clés de la réussite dans l''Agro-Tech',
       '2026-06-28 18:30:00+00', 'Virtuel (Lien Zoom fourni à l''inscription)',
       'Webinaire',
       'Découvrez comment les technologies modernes peuvent améliorer la productivité pastorale et agricole.',
       'https://images.unsplash.com/photo-1530595467537-0b5996c41f2d?w=600&fit=crop&q=80',
       95, member_ibrahima),
    ('e0000004-0000-0000-0000-000000000004',
       'Rencontre Réseau & Networking Local',
       '2026-06-20 19:00:00+00', 'Espace Rive Gauche, Bruxelles, Belgique',
       'Réunion',
       'Une soirée informelle de réseautage pour faire connaissance avec les nouveaux professionnels arrivés dans la région de Bruxelles.',
       'https://images.unsplash.com/photo-1511578314322-379afb476865?w=600&fit=crop&q=80',
       45, member_ousmane),
    ('e0000005-0000-0000-0000-000000000005',
       'Atelier de Poésie et Littérature Pulaar',
       '2026-07-02 15:00:00+00', 'Bibliothèque Nationale, Conakry, Guinée',
       'Réunion',
       'Une séance de lecture collective de poèmes traditionnels et modernes Pulaar, suivie d''un atelier d''écriture créative ouvert à tous.',
       'https://images.unsplash.com/photo-1506880018603-83d5b814b5a6?w=600&fit=crop&q=80',
       30, member_aissatou)
  on conflict (id) do nothing;

  ----------------------------------------------------------------------------
  -- jobs
  ----------------------------------------------------------------------------
  insert into public.jobs
    (id, title, company, company_initials, location, type, domain, posted_ago, badge, badge_type, posted_by)
  values
    ('f0000001-0000-0000-0000-000000000001', 'Senior Frontend Engineer', 'TechNova Solutions', 'TN',
       'Dakar, Sénégal (Hybride)', 'Full-time', 'Tech', 'Il y a 2 jours',
       'Alumni Présent', 'alumni', member_amadou),
    ('f0000002-0000-0000-0000-000000000002', 'Analyste Données Agricoles', 'Sahel Agri-Tech', 'SA',
       'Bamako, Mali (Sur site)', 'Contract', 'Agriculture', 'Il y a 5 jours',
       'Partenaire Communautaire', 'partner', member_ibrahima),
    ('f0000003-0000-0000-0000-000000000003', 'Consultant Santé Publique', 'Global Health Initiative', 'GH',
       'Remote (Global)', 'Mission Freelance', 'Santé', 'Il y a 1 semaine',
       null, null, member_aissatou),
    ('f0000004-0000-0000-0000-000000000004', 'Stage Auditeur Financier', 'Fulani Network Finance', 'FN',
       'Conakry, Guinée (Hybride)', 'Internship', 'Finance', 'Aujourd''hui',
       'Pour Étudiants', 'student', member_ibrahima),
    ('f0000005-0000-0000-0000-000000000005', 'Product Designer UX/UI', 'AfriStart', 'AS',
       'Paris, France (Remote)', 'Full-time', 'Design', 'Il y a 3 jours',
       null, null, member_aaliyah)
  on conflict (id) do nothing;

  ----------------------------------------------------------------------------
  -- marketplace_services
  ----------------------------------------------------------------------------
  insert into public.marketplace_services
    (id, category, category_icon, title, description, rating, review_count, price, price_label, cta_label, image_url, provider_id)
  values
    ('10000001-0000-0000-0000-000000000001', 'Traduction', 'translate',
       'Traduction Pulaar - Français Professionnelle',
       'Services de traduction certifiés pour documents administratifs, commerciaux et littéraires. Précision et confidentialité garanties.',
       4.9, 124, '35k FCFA', 'À partir de', 'Réserver',
       'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=600&q=80',
       member_aaliyah),
    ('10000002-0000-0000-0000-000000000002', 'Dév Web', 'code',
       'Création Site E-commerce Sur Mesure',
       'Boutiques en ligne performantes, design responsif et intégration de paiements locaux (Mobile Money).',
       5.0, 42, '250k FCFA', 'Forfait', 'Réserver',
       'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=600&q=80',
       member_amadou),
    ('10000003-0000-0000-0000-000000000003', 'Transport', 'local_shipping',
       'Logistique & Transport Inter-urbain',
       'Transport sécurisé de marchandises avec suivi GPS en temps réel. Flotte moderne et chauffeurs expérimentés.',
       4.7, 89, 'Sur devis', 'Par trajet', 'Demander devis',
       'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?w=600&q=80',
       member_ibrahima),
    ('10000004-0000-0000-0000-000000000004', 'Immobilier', 'home',
       'Conseil Immobilier Diaspora',
       'Investissement immobilier au Sénégal et en Guinée pour la diaspora. Accompagnement complet de A à Z.',
       4.8, 56, '50k FCFA', 'Consultation', 'Contacter',
       'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=600&q=80',
       member_ousmane)
  on conflict (id) do nothing;

  ----------------------------------------------------------------------------
  -- books
  ----------------------------------------------------------------------------
  insert into public.books (id, title, author, emoji, color_hex, category_index) values
    ('20000001-0000-0000-0000-000000000001', 'Grammaire Pulaar',           'Jean-Marie Gibbal', '📖', '#1B4332', 1),
    ('20000002-0000-0000-0000-000000000002', 'Histoire des Peuls',         'Théodore Monod',    '🏺', '#735C00', 3),
    ('20000003-0000-0000-0000-000000000003', 'Contes du Fouta',            'Bouba Diallo',      '🌙', '#002842', 1),
    ('20000004-0000-0000-0000-000000000004', 'Dictionnaire Fulfulde-Fr',   'Alfa Sow',          '📚', '#3D3D3D', 2)
  on conflict (id) do nothing;

  ----------------------------------------------------------------------------
  -- transactions (for member_aaliyah — fallback profile)
  ----------------------------------------------------------------------------
  insert into public.transactions
    (id, user_id, label, date, method, amount, icon, occurred_at)
  values
    ('30000001-0000-0000-0000-000000000001', member_aaliyah,
       'Donation Projet Puits',  '10 Sept 2024 • Carte Bancaire', 'Carte Bancaire', -25.0,  'water_drop',  now() - interval '270 days'),
    ('30000002-0000-0000-0000-000000000002', member_aaliyah,
       'Abonnement Annuel',      '01 Jan 2024 • Prélèvement',     'Prélèvement',    -100.0, 'workspace_premium', now() - interval '500 days'),
    ('30000003-0000-0000-0000-000000000003', member_aaliyah,
       'Donation Bourses',       '15 Déc 2023 • Mobile Money',     'Mobile Money',   -50.0,  'school',      now() - interval '550 days'),
    ('30000004-0000-0000-0000-000000000004', member_aaliyah,
       'Cotisation Mensuelle',   '01 Nov 2023 • Prélèvement',     'Prélèvement',    -20.0,  'groups',      now() - interval '590 days')
  on conflict (id) do nothing;

  ----------------------------------------------------------------------------
  -- community_projects
  ----------------------------------------------------------------------------
  insert into public.community_projects
    (id, title, location, icon, color, current_amount, target_amount, currency)
  values
    ('40000001-0000-0000-0000-000000000001',
       'Projet Eau Potable', 'Région de Ziguinchor, SN', 'water_drop', '#003F63',
       375000, 500000, 'FCFA'),
    ('40000002-0000-0000-0000-000000000002',
       'Bourses Universitaires', 'Diaspora mondiale', 'school', '#FED65B',
       200000, 500000, 'FCFA')
  on conflict (id) do nothing;

  ----------------------------------------------------------------------------
  -- subscription for member_aaliyah
  ----------------------------------------------------------------------------
  insert into public.subscriptions
    (user_id, plan, amount, currency, next_due_at)
  values
    (member_aaliyah, 'community', 50.0, 'FCFA', '2024-10-15 00:00:00+00')
  on conflict (user_id) do nothing;
end $$;
