--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.4
-- Dumped by pg_dump version 9.5.4
CREATE DATABASE tsingyun_gis;
\c tsingyun_gis






SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

-- Name: postgis; Type: EXTENSION; Schema: -; Owner:
create extension postgis;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


SET search_path = public, pg_catalog;

--
-- Name: poi_point_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE poi_point_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE poi_point_id_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: poi_point; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE poi_point (
    id text DEFAULT nextval('poi_point_id_seq'::regclass) NOT NULL,
    poi_id character varying(128) NOT NULL,
    poi_type character varying(20) NOT NULL,
    poi_name character varying(128) DEFAULT NULL::character varying,
    org_code character varying(128) DEFAULT NULL::character varying,
    org_type character varying(20) DEFAULT NULL::character varying,
    org_name character varying(128) DEFAULT NULL::character varying,
    geom geometry(Point,4326),
    deleted integer DEFAULT 0,
    version integer DEFAULT 1,
    create_time text,
    update_time text,
    tenant_id bigint,
    department character varying(500) DEFAULT NULL::character varying
);


ALTER TABLE poi_point OWNER TO postgres;

--
-- Name: COLUMN poi_point.tenant_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN poi_point.tenant_id IS '租户ID';


--
-- Name: poi_polygon_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE poi_polygon_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE poi_polygon_id_seq OWNER TO postgres;

--
-- Name: poi_polygon; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE poi_polygon (
    id text DEFAULT nextval('poi_polygon_id_seq'::regclass) NOT NULL,
    poi_id character varying(128) NOT NULL,
    poi_type character varying(20) NOT NULL,
    poi_name character varying(128) DEFAULT NULL::character varying,
    org_code character varying(128) DEFAULT NULL::character varying,
    org_type character varying(20) DEFAULT NULL::character varying,
    org_name character varying(128) DEFAULT NULL::character varying,
    geom geometry(Polygon,4326),
    deleted integer DEFAULT 0,
    version integer DEFAULT 1,
    create_time text,
    update_time text,
    tenant_id bigint,
    department character varying(500) DEFAULT NULL::character varying
);


ALTER TABLE poi_polygon OWNER TO postgres;

--
-- Name: COLUMN poi_polygon.tenant_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN poi_polygon.tenant_id IS '租户ID';


--
-- Name: poi_polyline_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE poi_polyline_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE poi_polyline_id_seq OWNER TO postgres;

--
-- Name: poi_polyline; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE poi_polyline (
    id text DEFAULT nextval('poi_polyline_id_seq'::regclass) NOT NULL,
    poi_id character varying(128) NOT NULL,
    poi_type character varying(20) NOT NULL,
    poi_name character varying(128) DEFAULT NULL::character varying,
    org_code character varying(128) DEFAULT NULL::character varying,
    org_type character varying(20) DEFAULT NULL::character varying,
    org_name character varying(128) DEFAULT NULL::character varying,
    geom geometry(LineString,4326),
    deleted integer DEFAULT 0,
    version integer DEFAULT 1,
    create_time text,
    update_time text,
    tenant_id bigint,
    department character varying(500) DEFAULT NULL::character varying
);


ALTER TABLE poi_polyline OWNER TO postgres;

--
-- Name: COLUMN poi_polyline.tenant_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN poi_polyline.tenant_id IS '租户ID';


--
-- Data for Name: poi_point; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY poi_point (id, poi_id, poi_type, poi_name, org_code, org_type, org_name, geom, deleted, version, create_time, update_time, tenant_id, department) FROM stdin;
2	596906816026181632	1001	\N	\N	\N	\N	0101000020E6100000BFF2F35ACED05C408E3633B9C8864040	0	1	\N	\N	477315026940592128	\N
3	597972917338243072	1001	\N	\N	\N	\N	0101000020E6100000EB927E5A37D15C40A73BC57D19874040	0	1	\N	\N	477315026940592128	\N
5	598284290047868928	1001	\N	\N	\N	\N	0101000020E6100000184D0F6E54D15C405AB75DB76C884040	0	1	\N	\N	477315026940592128	\N
6	598783843863887872	503	\N	\N	\N	\N	0101000020E6100000DDDBAF4F44D15C40405C92D5A1894040	0	1	\N	\N	477315026940592128	\N
10	599002952308359168	503	\N	\N	\N	\N	0101000020E6100000E628B3C64ED15C409C294771048A4040	0	1	\N	\N	477315026940592128	\N
11	599002998319874048	503	\N	\N	\N	\N	0101000020E6100000E628B3C64ED15C409C294771048A4040	0	1	\N	\N	477315026940592128	\N
12	599003025733844992	503	\N	\N	\N	\N	0101000020E6100000E628B3C64ED15C409C294771048A4040	0	1	\N	\N	477315026940592128	\N
13	599003540538523648	503	\N	\N	\N	\N	0101000020E6100000D9BEE73266D15C4082ADE60EF1894040	0	1	\N	\N	477315026940592128	\N
14	599006983135166464	503	\N	\N	\N	\N	0101000020E61000001821748B75D15C40C75AA622E4894040	0	1	\N	\N	477315026940592128	\N
15	599010692812505088	503	\N	\N	\N	\N	0101000020E6100000C709E9E399D15C402C4B28AC318A4040	0	1	\N	\N	477315026940592128	\N
16	599010696545435648	503	\N	\N	\N	\N	0101000020E6100000C709E9E399D15C402C4B28AC318A4040	0	1	\N	\N	477315026940592128	\N
17	599010702614593536	503	\N	\N	\N	\N	0101000020E6100000C709E9E399D15C402C4B28AC318A4040	0	1	\N	\N	477315026940592128	\N
18	599010705047289856	503	\N	\N	\N	\N	0101000020E6100000C709E9E399D15C402C4B28AC318A4040	0	1	\N	\N	477315026940592128	\N
19	599010769593434112	503	\N	\N	\N	\N	0101000020E6100000C709E9E399D15C402C4B28AC318A4040	0	1	\N	\N	477315026940592128	\N
20	599010770931417088	503	\N	\N	\N	\N	0101000020E6100000C709E9E399D15C402C4B28AC318A4040	0	1	\N	\N	477315026940592128	\N
21	599010775490625536	503	\N	\N	\N	\N	0101000020E6100000C709E9E399D15C402C4B28AC318A4040	0	1	\N	\N	477315026940592128	\N
22	599010776795054080	503	\N	\N	\N	\N	0101000020E6100000C709E9E399D15C402C4B28AC318A4040	0	1	\N	\N	477315026940592128	\N
23	599010794633428992	503	\N	\N	\N	\N	0101000020E6100000C709E9E399D15C402C4B28AC318A4040	0	1	\N	\N	477315026940592128	\N
24	599010804674592768	503	\N	\N	\N	\N	0101000020E6100000747ED23394D05C40A86777220E8A4040	0	1	\N	\N	477315026940592128	\N
25	599010808948588544	503	\N	\N	\N	\N	0101000020E6100000747ED23394D05C40A86777220E8A4040	0	1	\N	\N	477315026940592128	\N
26	599010810089439232	503	\N	\N	\N	\N	0101000020E6100000747ED23394D05C40A86777220E8A4040	0	1	\N	\N	477315026940592128	\N
27	599010810391429120	503	\N	\N	\N	\N	0101000020E6100000747ED23394D05C40A86777220E8A4040	0	1	\N	\N	477315026940592128	\N
28	599010811179958272	503	\N	\N	\N	\N	0101000020E6100000747ED23394D05C40A86777220E8A4040	0	1	\N	\N	477315026940592128	\N
29	599010811960098816	503	\N	\N	\N	\N	0101000020E6100000747ED23394D05C40A86777220E8A4040	0	1	\N	\N	477315026940592128	\N
30	599010812757016576	503	\N	\N	\N	\N	0101000020E6100000747ED23394D05C40A86777220E8A4040	0	1	\N	\N	477315026940592128	\N
32	598811506137628672	503	\N	\N	\N	\N	0101000020E61000002C52D33C55D15C404877F598C0894040	0	1	\N	\N	477315026940592128	\N
33	598800303935979520	503	\N	\N	\N	\N	0101000020E61000007E8BD53D6ED05C40A2F0A8844B8A4040	0	1	\N	\N	477315026940592128	\N
35	598785815446814720	503	\N	\N	\N	\N	0101000020E6100000B247E78AF3D15C40B2DE45C0D0894040	0	1	\N	\N	477315026940592128	\N
\.


--
-- Name: poi_point_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('poi_point_id_seq', 38, true);


--
-- Data for Name: poi_polygon; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY poi_polygon (id, poi_id, poi_type, poi_name, org_code, org_type, org_name, geom, deleted, version, create_time, update_time, tenant_id, department) FROM stdin;
\.


--
-- Name: poi_polygon_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('poi_polygon_id_seq', 1, false);


--
-- Data for Name: poi_polyline; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY poi_polyline (id, poi_id, poi_type, poi_name, org_code, org_type, org_name, geom, deleted, version, create_time, update_time, tenant_id, department) FROM stdin;
\.


--
-- Name: poi_polyline_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('poi_polyline_id_seq', 1, false);


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY spatial_ref_sys  FROM stdin;
\.


--
-- Name: poi_point_constraint_unique_poi_id_type; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY poi_point
    ADD CONSTRAINT poi_point_constraint_unique_poi_id_type UNIQUE (poi_id, poi_type);


--
-- Name: poi_point_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY poi_point
    ADD CONSTRAINT poi_point_pk PRIMARY KEY (id);


--
-- Name: poi_polygon_constraint_unique_poi_id_type; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY poi_polygon
    ADD CONSTRAINT poi_polygon_constraint_unique_poi_id_type UNIQUE (poi_id, poi_type);


--
-- Name: poi_polygon_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY poi_polygon
    ADD CONSTRAINT poi_polygon_pk PRIMARY KEY (id);


--
-- Name: poi_polyline_constraint_unique_poi_id_type; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY poi_polyline
    ADD CONSTRAINT poi_polyline_constraint_unique_poi_id_type UNIQUE (poi_id, poi_type);


--
-- Name: poi_polyline_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY poi_polyline
    ADD CONSTRAINT poi_polyline_pk PRIMARY KEY (id);


--
-- Name: poi_point_gix; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX poi_point_gix ON poi_point USING gist (geom);


--
-- Name: poi_polygon_gix; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX poi_polygon_gix ON poi_polygon USING gist (geom);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

