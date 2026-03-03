--
-- PostgreSQL database dump
--

-- Dumped from database version 12.4
-- Dumped by pg_dump version 12.4

-- Started on 2026-03-03 17:46:17

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
-- TOC entry 216 (class 1255 OID 16693)
-- Name: calcular_vencimiento(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calcular_vencimiento() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.fecha_vencimiento :=
        NEW.fecha_publicacion + (NEW.duracion_dias || ' days')::INTERVAL;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.calcular_vencimiento() OWNER TO postgres;

--
-- TOC entry 215 (class 1255 OID 16689)
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
-- TOC entry 214 (class 1255 OID 16687)
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
-- TOC entry 213 (class 1255 OID 16685)
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
-- TOC entry 211 (class 1259 OID 16697)
-- Name: categorias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categorias (
    id bigint NOT NULL,
    nombre character varying(100) NOT NULL,
    categoria_padre_id bigint
);


ALTER TABLE public.categorias OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 16695)
-- Name: categorias_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categorias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.categorias_id_seq OWNER TO postgres;

--
-- TOC entry 2912 (class 0 OID 0)
-- Dependencies: 210
-- Name: categorias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categorias_id_seq OWNED BY public.categorias.id;


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
-- TOC entry 2913 (class 0 OID 0)
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
    tienda_id bigint NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion text,
    precio_minorista numeric(12,2) NOT NULL,
    precio_mayorista numeric(12,2) NOT NULL,
    cantidad_minima_mayorista integer DEFAULT 10,
    stock integer NOT NULL,
    fecha_publicacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    duracion_dias integer,
    fecha_vencimiento timestamp without time zone,
    categoria_id bigint,
    CONSTRAINT productos_cantidad_minima_mayorista_check CHECK ((cantidad_minima_mayorista > 0)),
    CONSTRAINT productos_duracion_dias_check CHECK ((duracion_dias > 0)),
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
-- TOC entry 2914 (class 0 OID 0)
-- Dependencies: 205
-- Name: productos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.productos_id_seq OWNED BY public.productos.id;


--
-- TOC entry 204 (class 1259 OID 16607)
-- Name: tiendas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tiendas (
    usuario_id bigint NOT NULL,
    nombre_tienda character varying(150) NOT NULL,
    direccion text,
    telefono character varying(20),
    id bigint NOT NULL
);


ALTER TABLE public.tiendas OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 16726)
-- Name: tiendas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tiendas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tiendas_id_seq OWNER TO postgres;

--
-- TOC entry 2915 (class 0 OID 0)
-- Dependencies: 212
-- Name: tiendas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tiendas_id_seq OWNED BY public.tiendas.id;


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
-- TOC entry 2916 (class 0 OID 0)
-- Dependencies: 202
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- TOC entry 2742 (class 2604 OID 16700)
-- Name: categorias id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias ALTER COLUMN id SET DEFAULT nextval('public.categorias_id_seq'::regclass);


--
-- TOC entry 2737 (class 2604 OID 16656)
-- Name: pedidos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos ALTER COLUMN id SET DEFAULT nextval('public.pedidos_id_seq'::regclass);


--
-- TOC entry 2729 (class 2604 OID 16625)
-- Name: productos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productos ALTER COLUMN id SET DEFAULT nextval('public.productos_id_seq'::regclass);


--
-- TOC entry 2728 (class 2604 OID 16728)
-- Name: tiendas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tiendas ALTER COLUMN id SET DEFAULT nextval('public.tiendas_id_seq'::regclass);


--
-- TOC entry 2725 (class 2604 OID 16597)
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- TOC entry 2905 (class 0 OID 16697)
-- Dependencies: 211
-- Data for Name: categorias; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2903 (class 0 OID 16666)
-- Dependencies: 209
-- Data for Name: detalle_pedido; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2902 (class 0 OID 16653)
-- Dependencies: 208
-- Data for Name: pedidos; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2900 (class 0 OID 16622)
-- Dependencies: 206
-- Data for Name: productos; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.productos VALUES (1, 1, 'Camiseta Oversize', 'Camiseta algod¢n premium', 50000.00, 35000.00, 10, 100, '2026-03-03 17:37:29.087077', 30, '2026-04-02 17:37:29.087077', NULL);


--
-- TOC entry 2898 (class 0 OID 16607)
-- Dependencies: 204
-- Data for Name: tiendas; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tiendas VALUES (1, 'Moda Urbana', 'Bogot ', '3001234567', 1);


--
-- TOC entry 2897 (class 0 OID 16594)
-- Dependencies: 203
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.usuarios VALUES (1, 'Carlos', 'Perez', 'carlos@test.com', 'hash123', 'VENDEDOR', '2026-03-03 17:36:29.819915');


--
-- TOC entry 2917 (class 0 OID 0)
-- Dependencies: 210
-- Name: categorias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categorias_id_seq', 1, false);


--
-- TOC entry 2918 (class 0 OID 0)
-- Dependencies: 207
-- Name: pedidos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pedidos_id_seq', 1, false);


--
-- TOC entry 2919 (class 0 OID 0)
-- Dependencies: 205
-- Name: productos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.productos_id_seq', 1, true);


--
-- TOC entry 2920 (class 0 OID 0)
-- Dependencies: 212
-- Name: tiendas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tiendas_id_seq', 1, true);


--
-- TOC entry 2921 (class 0 OID 0)
-- Dependencies: 202
-- Name: usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuarios_id_seq', 1, true);


--
-- TOC entry 2758 (class 2606 OID 16702)
-- Name: categorias categorias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_pkey PRIMARY KEY (id);


--
-- TOC entry 2756 (class 2606 OID 16672)
-- Name: detalle_pedido detalle_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_pkey PRIMARY KEY (pedido_id, producto_id);


--
-- TOC entry 2754 (class 2606 OID 16660)
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (id);


--
-- TOC entry 2751 (class 2606 OID 16635)
-- Name: productos productos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_pkey PRIMARY KEY (id);


--
-- TOC entry 2748 (class 2606 OID 16737)
-- Name: tiendas tiendas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tiendas
    ADD CONSTRAINT tiendas_pkey PRIMARY KEY (id);


--
-- TOC entry 2744 (class 2606 OID 16606)
-- Name: usuarios usuarios_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_email_key UNIQUE (email);


--
-- TOC entry 2746 (class 2606 OID 16604)
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- TOC entry 2752 (class 1259 OID 16684)
-- Name: idx_pedidos_usuario; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pedidos_usuario ON public.pedidos USING btree (usuario_id);


--
-- TOC entry 2749 (class 1259 OID 16683)
-- Name: idx_productos_vendedor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_productos_vendedor ON public.productos USING btree (tienda_id);


--
-- TOC entry 2769 (class 2620 OID 16690)
-- Name: detalle_pedido trigger_descontar_stock; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_descontar_stock BEFORE INSERT ON public.detalle_pedido FOR EACH ROW EXECUTE FUNCTION public.descontar_stock();


--
-- TOC entry 2767 (class 2620 OID 16694)
-- Name: productos trigger_fecha_vencimiento; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_fecha_vencimiento BEFORE INSERT OR UPDATE ON public.productos FOR EACH ROW WHEN ((new.duracion_dias IS NOT NULL)) EXECUTE FUNCTION public.calcular_vencimiento();


--
-- TOC entry 2768 (class 2620 OID 16688)
-- Name: pedidos trigger_validar_comprador; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_validar_comprador BEFORE INSERT ON public.pedidos FOR EACH ROW EXECUTE FUNCTION public.validar_comprador();


--
-- TOC entry 2766 (class 2620 OID 16686)
-- Name: tiendas trigger_validar_vendedor; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_validar_vendedor BEFORE INSERT ON public.tiendas FOR EACH ROW EXECUTE FUNCTION public.validar_vendedor();


--
-- TOC entry 2765 (class 2606 OID 16703)
-- Name: categorias categorias_categoria_padre_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_categoria_padre_id_fkey FOREIGN KEY (categoria_padre_id) REFERENCES public.categorias(id) ON DELETE SET NULL;


--
-- TOC entry 2763 (class 2606 OID 16673)
-- Name: detalle_pedido detalle_pedido_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedidos(id) ON DELETE CASCADE;


--
-- TOC entry 2764 (class 2606 OID 16678)
-- Name: detalle_pedido detalle_pedido_producto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_pedido
    ADD CONSTRAINT detalle_pedido_producto_id_fkey FOREIGN KEY (producto_id) REFERENCES public.productos(id);


--
-- TOC entry 2760 (class 2606 OID 16708)
-- Name: productos fk_producto_categoria; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT fk_producto_categoria FOREIGN KEY (categoria_id) REFERENCES public.categorias(id);


--
-- TOC entry 2761 (class 2606 OID 16745)
-- Name: productos fk_productos_tienda; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT fk_productos_tienda FOREIGN KEY (tienda_id) REFERENCES public.tiendas(id) ON DELETE CASCADE;


--
-- TOC entry 2762 (class 2606 OID 16661)
-- Name: pedidos pedidos_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- TOC entry 2759 (class 2606 OID 16738)
-- Name: tiendas tiendas_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tiendas
    ADD CONSTRAINT tiendas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


-- Completed on 2026-03-03 17:46:17

--
-- PostgreSQL database dump complete
--

