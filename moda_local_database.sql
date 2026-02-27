--
-- PostgreSQL database dump
--

-- Dumped from database version 12.4
-- Dumped by pg_dump version 12.4

-- Started on 2026-02-24 19:10:50

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 645 (class 1247 OID 16642)
-- Name: estado_pedido; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_pedido AS ENUM (
    'PENDIENTE',
    'PAGADO',
    'ENVIADO',
    'CANCELADO'
);


ALTER TYPE public.estado_pedido OWNER TO postgres;

--
-- TOC entry 212 (class 1255 OID 16689)
-- Name: descontar_stock(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.descontar_stock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    stock_actual INT;
BEGIN
    SELECT stock INTO stock_actual
    FROM productos
    WHERE id = NEW.producto_id
    FOR UPDATE;

    IF stock_actual < NEW.cantidad THEN
        RAISE EXCEPTION 'Stock insuficiente';
    END IF;

    UPDATE productos
    SET stock = stock - NEW.cantidad
    WHERE id = NEW.producto_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.descontar_stock() OWNER TO postgres;

--
-- TOC entry 211 (class 1255 OID 16687)
-- Name: validar_comprador(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validar_comprador() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
IF (SELECT tipo_usuario FROM usuarios WHERE id = NEW.usuario_id) != 'COMPRADOR' THEN
RAISE EXCEPTION 'solo compradores pueden hacer pedidos';
END IF;
RETURN NEW;
END;
$$;


ALTER FUNCTION public.validar_comprador() OWNER TO postgres;

--
-- TOC entry 210 (class 1255 OID 16685)
-- Name: validar_vendedor(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validar_vendedor() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
IF (SELECT tipo_usuario FROM usuarios WHERE id = NEW.usuario_id) != 'VENDEDOR' THEN
RAISE EXCEPTION 'solo usuarios VENDEDOR pueden registrarse como vendedor';
END IF;
RETURN NEW;
END;
$$;


ALTER FUNCTION public.validar_vendedor() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 209 (class 1259 OID 16666)
-- Name: detalle_pedido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.detalle_pedido (
    pedido_id bigint NOT NULL,
    producto_id bigint NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(12,2) NOT NULL,
    CONSTRAINT detalle_pedido_cantidad_check CHECK ((cantidad > 0)),
    CONSTRAINT detalle_pedido_precio_unitario_check CHECK ((precio_unitario >= (0)::numeric))
);


ALTER TABLE public.detalle_pedido OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 16653)
-- Name: pedidos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pedidos (
    id bigint NOT NULL,
    usuario_id bigint NOT NULL,
    fecha timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    estado public.estado_pedido DEFAULT 'PENDIENTE'::public.estado_pedido
);


ALTER TABLE public.pedidos OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 16651)
-- Name: pedidos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pedidos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pedidos_id_seq OWNER TO postgres;

--
-- TOC entry 2891 (class 0 OID 0)
-- Dependencies: 207
-- Name: pedidos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pedidos_id_seq OWNED BY public.pedidos.id;


--
-- TOC entry 206 (class 1259 OID 16622)
-- Name: productos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.productos (
    id bigint NOT NULL,
    vendedor_id bigint NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion text,
    precio_minorista numeric(12,2) NOT NULL,
    precio_mayorista numeric(12,2) NOT NULL,
    cantidad_minima_mayorista integer DEFAULT 10,
    stock integer NOT NULL,
    CONSTRAINT productos_cantidad_minima_mayorista_check CHECK ((cantidad_minima_mayorista > 0)),
    CONSTRAINT productos_precio_mayorista_check CHECK ((precio_mayorista >= (0)::numeric)),
    CONSTRAINT productos_precio_minorista_check CHECK ((precio_minorista >= (0)::numeric)),
    CONSTRAINT productos_stock_check CHECK ((stock >= 0))
);


ALTER TABLE public.productos OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 16620)
-- Name: productos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.productos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.productos_id_seq OWNER TO postgres;

--
-- TOC entry 2892 (class 0 OID 0)
-- Dependencies: 205
-- Name: productos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.productos_id_seq OWNED BY public.productos.id;


--
-- TOC entry 203 (class 1259 OID 16594)
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    id bigint NOT NULL,
    nombre character varying(100) NOT NULL,
    apellido character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    passworld_hash character varying(255) NOT NULL,
    tipo_usuario character varying(20) NOT NULL,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT usuarios_tipo_usuario_check CHECK (((tipo_usuario)::text = ANY ((ARRAY['COMPRADOR'::character varying, 'VENDEDOR'::character varying, 'ADMIN'::character varying])::text[])))
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 16592)
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.usuarios_id_seq OWNER TO postgres;

--
-- TOC entry 2893 (class 0 OID 0)
-- Dependencies: 202
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- TOC entry 204 (class 1259 OID 16607)
-- Name: vendedores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vendedores (
    usuario_id bigint NOT NULL,
    nombre_tienda character varying(150) NOT NULL,
    direccion text,
    telefono character varying(20)
);


ALTER TABLE public.vendedores OWNER TO postgres;

--
-- TOC entry 2725 (class 2604 OID 16656)
-- Name: pedidos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos ALTER COLUMN id SET DEFAULT nextval('public.pedidos_id_seq'::regclass);


--
-- TOC entry 2719 (class 2604 OID 16625)
-- Name: productos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productos ALTER COLUMN id SET DEFAULT nextval('public.productos_id_seq'::regclass);


--
-- TOC entry 2716 (class 2604 OID 16597)
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- TOC entry 2885 (class 0 OID 16666)
-- Dependencies: 209
-- Data for Name: detalle_pedido; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2884 (class 0 OID 16653)
-- Dependencies: 208
-- Data for Name: pedidos; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2882 (class 0 OID 16622)
-- Dependencies: 206
-- Data for Name: productos; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2879 (class 0 OID 16594)
-- Dependencies: 203
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2880 (class 0 OID 16607)
-- Dependencies: 204
-- Data for Name: vendedores; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2894 (class 0 OID 0)
-- Dependencies: 207
-- Name: pedidos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pedidos_id_seq', 1, false);


--
-- TOC entry 2895 (class 0 OID 0)
-- Dependencies: 205
-- Name: productos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.productos_id_seq', 1, false);


--
-- TOC entry 2896 (class 0 OID 0)
-- Dependencies: 202
-- Name: usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuarios_id_seq', 1, false);


--
-- TOC entry 2743 (class 2606 OID 16672)
-- Name: detalle_pedido detalle_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_pkey PRIMARY KEY (pedido_id, producto_id);


--
-- TOC entry 2741 (class 2606 OID 16660)
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (id);


--
-- TOC entry 2738 (class 2606 OID 16635)
-- Name: productos productos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_pkey PRIMARY KEY (id);


--
-- TOC entry 2731 (class 2606 OID 16606)
-- Name: usuarios usuarios_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_email_key UNIQUE (email);


--
-- TOC entry 2733 (class 2606 OID 16604)
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- TOC entry 2735 (class 2606 OID 16614)
-- Name: vendedores vendedores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendedores
    ADD CONSTRAINT vendedores_pkey PRIMARY KEY (usuario_id);


--
-- TOC entry 2739 (class 1259 OID 16684)
-- Name: idx_pedidos_usuario; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pedidos_usuario ON public.pedidos USING btree (usuario_id);


--
-- TOC entry 2736 (class 1259 OID 16683)
-- Name: idx_productos_vendedor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_productos_vendedor ON public.productos USING btree (vendedor_id);


--
-- TOC entry 2751 (class 2620 OID 16690)
-- Name: detalle_pedido trigger_descontar_stock; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_descontar_stock BEFORE INSERT ON public.detalle_pedido FOR EACH ROW EXECUTE FUNCTION public.descontar_stock();


--
-- TOC entry 2750 (class 2620 OID 16688)
-- Name: pedidos trigger_validar_comprador; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_validar_comprador BEFORE INSERT ON public.pedidos FOR EACH ROW EXECUTE FUNCTION public.validar_comprador();


--
-- TOC entry 2749 (class 2620 OID 16686)
-- Name: vendedores trigger_validar_vendedor; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_validar_vendedor BEFORE INSERT ON public.vendedores FOR EACH ROW EXECUTE FUNCTION public.validar_vendedor();


--
-- TOC entry 2747 (class 2606 OID 16673)
-- Name: detalle_pedido detalle_pedido_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedidos(id) ON DELETE CASCADE;


--
-- TOC entry 2748 (class 2606 OID 16678)
-- Name: detalle_pedido detalle_pedido_producto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_producto_id_fkey FOREIGN KEY (producto_id) REFERENCES public.productos(id);


--
-- TOC entry 2746 (class 2606 OID 16661)
-- Name: pedidos pedidos_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- TOC entry 2745 (class 2606 OID 16636)
-- Name: productos productos_vendedor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_vendedor_id_fkey FOREIGN KEY (vendedor_id) REFERENCES public.vendedores(usuario_id) ON DELETE CASCADE;


--
-- TOC entry 2744 (class 2606 OID 16615)
-- Name: vendedores vendedores_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vendedores
    ADD CONSTRAINT vendedores_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


-- Completed on 2026-02-24 19:10:50

--
-- PostgreSQL database dump complete
--

