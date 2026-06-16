-- ============================================================================
-- 20260609_006_seed_organizations.sql
-- Pre-seed des grandes associations Peules et de leurs branches.
-- Idempotent (ON CONFLICT DO NOTHING) : peut être ré-exécuté sans erreur.
-- ============================================================================

-- ── Italie : Dental Fulbe Italia + 5 branches ─────────────────────────────
insert into public.organizations (id, name, country, description, status)
values (
  '00000000-0000-0000-0000-00000000a001',
  'Dental Fulbe Italia',
  'Italie',
  'Association principale des Peuls d''Italie, coordinatrice des branches locales et représentante officielle auprès des institutions italiennes.',
  'active'
) on conflict (id) do nothing;

insert into public.chapters (id, organization_id, name, city, description, status)
values
  ('00000000-0000-0000-0000-00000000b001', '00000000-0000-0000-0000-00000000a001',
   'Dental Fulbe Vicenza', 'Vicenza',
   'Branche locale de Vicenza, regroupant la communauté Peule de la région vénète.',
   'active'),
  ('00000000-0000-0000-0000-00000000b002', '00000000-0000-0000-0000-00000000a001',
   'Dental Fulbe Milano', 'Milan',
   'Branche de Milan, la plus active numériquement, organisatrice du festival annuel du Nord.',
   'active'),
  ('00000000-0000-0000-0000-00000000b003', '00000000-0000-0000-0000-00000000a001',
   'Dental Fulbe Roma', 'Rome',
   'Branche de Rome et du Latium, point de contact avec les institutions nationales et le Vatican.',
   'active'),
  ('00000000-0000-0000-0000-00000000b004', '00000000-0000-0000-0000-00000000a001',
   'Dental Fulbe Napoli', 'Naples',
   'Branche de Naples et de la Campanie.',
   'active'),
  ('00000000-0000-0000-0000-00000000b005', '00000000-0000-0000-0000-00000000a001',
   'Dental Fulbe Torino', 'Turin',
   'Branche du Piémont, axe industriel fort.',
   'active')
on conflict (id) do nothing;

-- ── France : Confédération Fulɓe France + 4 branches ─────────────────────
insert into public.organizations (id, name, country, description, status)
values (
  '00000000-0000-0000-0000-00000000a002',
  'Confédération Fulɓe France',
  'France',
  'Confédération nationale des associations Peules de France, fondée pour fédérer les branches locales et porter la voix de la diaspora.',
  'active'
) on conflict (id) do nothing;

insert into public.chapters (id, organization_id, name, city, description, status)
values
  ('00000000-0000-0000-0000-00000000b011', '00000000-0000-0000-0000-00000000a002',
   'CFF Île-de-France', 'Paris',
   'Branche parisienne, la plus importante en effectif.',
   'active'),
  ('00000000-0000-0000-0000-00000000b012', '00000000-0000-0000-0000-00000000a002',
   'CFF PACA', 'Marseille',
   'Branche Provence-Alpes-Côte d''Azur, organisatrice des rencontres méditerranéennes.',
   'active'),
  ('00000000-0000-0000-0000-00000000b013', '00000000-0000-0000-0000-00000000a002',
   'CFF Lyon', 'Lyon',
   'Branche Auvergne-Rhône-Alpes.',
   'active'),
  ('00000000-0000-0000-0000-00000000b014', '00000000-0000-0000-0000-00000000a002',
   'CFF Bordeaux', 'Bordeaux',
   'Branche Nouvelle-Aquitaine.',
   'active')
on conflict (id) do nothing;

-- ── Canada : Association Fulɓe Canada + 2 branches ───────────────────────
insert into public.organizations (id, name, country, description, status)
values (
  '00000000-0000-0000-0000-00000000a003',
  'Association Fulɓe Canada',
  'Canada',
  'Regroupement des Peuls du Canada, principalement implantés au Québec et en Ontario.',
  'active'
) on conflict (id) do nothing;

insert into public.chapters (id, organization_id, name, city, description, status)
values
  ('00000000-0000-0000-0000-00000000b021', '00000000-0000-0000-0000-00000000a003',
   'AFC Québec', 'Montréal',
   'Branche québécoise, la plus active du continent nord-américain.',
   'active'),
  ('00000000-0000-0000-0000-00000000b022', '00000000-0000-0000-0000-00000000a003',
   'AFC Ontario', 'Toronto',
   'Branche ontarienne, Toronto et sa banlieue.',
   'active')
on conflict (id) do nothing;
