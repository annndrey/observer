--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: plpgsql; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE PROCEDURAL LANGUAGE plpgsql;


ALTER PROCEDURAL LANGUAGE plpgsql OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- Name: dmdouble; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN dmdouble AS double precision;


ALTER DOMAIN public.dmdouble OWNER TO postgres;

--
-- Name: dminteger; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN dminteger AS integer;


ALTER DOMAIN public.dminteger OWNER TO postgres;

--
-- Name: dminteger_nn; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN dminteger_nn AS integer NOT NULL;


ALTER DOMAIN public.dminteger_nn OWNER TO postgres;

--
-- Name: dmsmallint; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN dmsmallint AS smallint;


ALTER DOMAIN public.dmsmallint OWNER TO postgres;

--
-- Name: dmsmallint_nn; Type: DOMAIN; Schema: public; Owner: postgres
--

CREATE DOMAIN dmsmallint_nn AS smallint NOT NULL;


ALTER DOMAIN public.dmsmallint_nn OWNER TO postgres;

--
-- Name: grad(double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION grad(latgrad double precision, latmin double precision) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
BEGIN
    
  RETURN (abs(latgrad)+latmin/60)*latgrad/abs(latgrad);
END;    
$$;


ALTER FUNCTION public.grad(latgrad double precision, latmin double precision) OWNER TO postgres;

--
-- Name: stn_in_reg(double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION stn_in_reg(latgradbeg double precision, latminbeg double precision, longradbeg double precision, lonminbeg double precision, fi_min double precision, lamb_min double precision, fi_max double precision, lamb_max double precision) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE Fi double precision;
DECLARE Lamb double precision;

BEGIN
   
    Fi=grad(latgradbeg,latminbeg);
    Lamb=grad(longradbeg,lonminbeg);

    IF (lamb_min>180 or lamb_max>180) and Lamb<0 THEN
      Lamb=Lamb+360; 
    END IF;
    
    IF Fi>=fi_min and Fi<=fi_max and Lamb>=lamb_min and Lamb<=lamb_max  
      THEN
        RETURN true;
      ELSE
        RETURN false; 
    END IF;  
     
END;   
$$;


ALTER FUNCTION public.stn_in_reg(latgradbeg double precision, latminbeg double precision, longradbeg double precision, lonminbeg double precision, fi_min double precision, lamb_min double precision, fi_max double precision, lamb_max double precision) OWNER TO postgres;

--
-- Name: stn_in_regxy(double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, integer, double precision, double precision, double precision, double precision, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION stn_in_regxy(latgradbeg double precision, latminbeg double precision, longradbeg double precision, lonminbeg double precision, fi_min double precision, lamb_min double precision, fi_max double precision, lamb_max double precision, xmax double precision, ymax double precision, type_proj integer, fi0_region double precision, x0_off double precision, y0_off double precision, dfi_map double precision, type_map integer, lambusermin integer, lambusermax integer, num_reg integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE Fi double precision;
DECLARE Lamb double precision;
DECLARE R0 double precision;
DECLARE alf double precision;
DECLARE C double precision;
DECLARE U double precision;
DECLARE r double precision;
DECLARE delt double precision;
DECLARE x double precision;
DECLARE y double precision;
DECLARE fi0_map double precision;
DECLARE Lamb0 double precision;
DECLARE fk double precision;

BEGIN
   
    Fi=grad(latgradbeg,latminbeg);
    Lamb=grad(longradbeg,lonminbeg);

    IF (lamb_min>180 OR lamb_max>180) AND Lamb<0 THEN
      Lamb=Lamb+360; 
    END IF;
    
    IF Fi>=fi_min AND Fi<=fi_max AND Lamb>=lamb_min AND Lamb<=lamb_max  
    THEN
         BEGIN

           IF type_proj=4 OR type_proj=5 THEN
             RETURN true;
           END IF;  
         
           R0=6371.116;
           alf=0.5;
           C=14523.0039;

           Lamb=Lamb*pi()/180;
           Fi=Fi*pi()/180;

           IF type_proj!=4 AND type_proj!=5 THEN
             BEGIN
               IF Lamb>0 THEN
                 IF Lamb>pi() THEN
                   Lamb=-(2*pi()-Lamb);
                 END IF;   
               ELSE 
                 BEGIN
                   Lamb=2*pi() + Lamb;
                   IF Lamb>pi() THEN 
                     Lamb=-(2*pi()-Lamb);
                   END IF;  
                 END;
               END IF;
             
               IF Lamb<-pi() THEN 
                 Lamb=2*pi() + Lamb;
               END IF;
             END;   
           END IF;

          IF type_proj=1 THEN
            BEGIN
              fi0_map=pi()/2-fi0_region;      
              IF type_map=2 THEN
                fi=-fi;
              END IF;  

              x= -2.*R0*cos(fi)*cos(lamb+fi0_map+dfi_map)/(1+sin(fi))-x0_off;

              IF type_map!=2 THEN
                y= -2.*R0*cos(fi)*sin(lamb+fi0_map+dfi_map)/(1+sin(fi))-y0_off;
              ELSE
                y= -2.*R0*cos(fi)*sin(lamb+fi0_map+dfi_map)/(1+sin(fi))+y0_off;
              END IF; 
              
              IF type_map=2 THEN
                y=-y;
              END IF;  
            END;
          END IF;

    
          IF type_proj=2 THEN
            BEGIN
              fi0_map=(pi()-fi0_region)*alf;          
              IF type_map=2 THEN
                Fi=-Fi;
              END IF;  

              IF Lamb<0 THEN
                BEGIN
                  IF (num_reg>=0 OR num_reg=-1) AND LambUserMax<0 AND LambUserMin>0  THEN
                     Lamb=2*pi() + Lamb;
                  END IF;   
                END;
              END IF;

              U=tan(pi()/4.+Fi/2.);
              r=C/power(U,alf);
              delt=alf*Lamb;
              x=-r*cos(delt+fi0_map+dfi_map)-x0_off;

              IF type_map!=2 THEN
                y=-r*sin(delt+fi0_map+dfi_map)-y0_off;
              ELSE
                y=-r*sin(delt+fi0_map+dfi_map)+y0_off;
              END IF;  

              IF type_map=2 THEN
                y=-y;
              END IF;  
            END;
          END IF;


          IF type_proj=3 THEN
            BEGIN
              fk=0.866025404;  /* cos(30) */

              IF num_reg<0 THEN
                BEGIN
                  IF LambUserMax>0 THEN
                    Lamb0=-179.5;
                  ELSE
                    BEGIN
                      IF LambUserMin<0 THEN
                        Lamb0=179.5;
                      ELSE
                        Lamb0=LambUserMax+0.5;
                      END IF;  
                    END;  
                  END IF;
                END;
              ELSE
                 IF num_reg=10 THEN
                   Lamb0=-110.0;
                 ELSE
                   Lamb0=-168.0;
                 END IF;  
              END IF;
              
              IF Lamb<Lamb0*pi()/180. THEN
                Lamb=2*pi()+Lamb;
              END IF;        
              fi0_map=0;

              x=R0*fk*(lamb+fi0_map)-x0_off;    
              y=(1+fk)*R0*tan(fi/2.)-y0_off;    
            END;  
          END IF;

          IF 0<=x AND x<=Xmax AND 0<=y AND y<=Ymax THEN 
            RETURN true;
          ELSE
            RETURN false;
          END IF;     
         END;  
      ELSE
        RETURN false; 
    END IF;  
     
END;   
$$;


ALTER FUNCTION public.stn_in_regxy(latgradbeg double precision, latminbeg double precision, longradbeg double precision, lonminbeg double precision, fi_min double precision, lamb_min double precision, fi_max double precision, lamb_max double precision, xmax double precision, ymax double precision, type_proj integer, fi0_region double precision, x0_off double precision, y0_off double precision, dfi_map double precision, type_map integer, lambusermin integer, lambusermax integer, num_reg integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: bioanalis_crab; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bioanalis_crab (
    myear dmsmallint_nn NOT NULL,
    vesselcode character varying(5) NOT NULL,
    numsurvey dmsmallint_nn NOT NULL,
    numstn dminteger_nn NOT NULL,
    numstrat dmsmallint NOT NULL,
    speciescode dmsmallint_nn NOT NULL,
    numspec dmsmallint_nn NOT NULL,
    lkarapax dmsmallint,
    wkarapax dmsmallint,
    clawhight dmdouble,
    weight dmsmallint,
    moltingst character varying(1),
    sex character varying(1),
    eggs character varying(3),
    leglost dmsmallint,
    illnesscode dmsmallint,
    observcode dmsmallint,
    comment1 character varying(50),
    comment2 character varying(50),
    comment3 character varying(50),
    comment4 character varying(50),
    label character varying(7)
);


ALTER TABLE public.bioanalis_crab OWNER TO postgres;

--
-- Name: bioanalis_craboid; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bioanalis_craboid (
    myear dmsmallint_nn NOT NULL,
    vesselcode character varying(5) NOT NULL,
    numsurvey dmsmallint_nn NOT NULL,
    numstn dminteger_nn NOT NULL,
    numstrat dmsmallint NOT NULL,
    speciescode dmsmallint_nn NOT NULL,
    numspec dmsmallint_nn NOT NULL,
    lkarapax dmsmallint,
    wkarapax dmsmallint,
    weight dmsmallint,
    moltingst character varying(1),
    sex character varying(1),
    eggs character varying(3),
    leglost dmsmallint,
    illnesscode dmsmallint,
    observcode dmsmallint,
    comment1 character varying(50),
    comment2 character varying(50),
    comment3 character varying(50),
    comment4 character varying(50),
    label character varying(7)
);


ALTER TABLE public.bioanalis_craboid OWNER TO postgres;

--
-- Name: bioanalis_echinoidea; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bioanalis_echinoidea (
    myear dmsmallint_nn NOT NULL,
    vesselcode character varying(5) NOT NULL,
    numsurvey dmsmallint_nn NOT NULL,
    numstn dminteger_nn NOT NULL,
    numstrat dmsmallint NOT NULL,
    speciescode dmsmallint_nn NOT NULL,
    numspec dmsmallint_nn NOT NULL,
    bodydiametr dmdouble,
    bodyheight dmdouble,
    bodyweight dmsmallint,
    gonadweight dmsmallint,
    sex character varying(1),
    gonadcolor character varying(1),
    gonadindex character varying(1),
    observcode dmsmallint,
    comment1 character varying(50),
    comment2 character varying(50),
    comment3 character varying(50),
    comment4 character varying(50)
);


ALTER TABLE public.bioanalis_echinoidea OWNER TO postgres;

--
-- Name: bioanalis_golotur; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bioanalis_golotur (
    myear dmsmallint_nn NOT NULL,
    vesselcode character varying(5) NOT NULL,
    numsurvey dmsmallint_nn NOT NULL,
    numstn dminteger_nn NOT NULL,
    numstrat dmsmallint NOT NULL,
    speciescode dmsmallint_nn NOT NULL,
    numspec dmsmallint_nn NOT NULL,
    weight dmdouble,
    kmmweight dmdouble,
    observcode dmsmallint,
    comment1 character varying(50),
    comment2 character varying(50),
    comment3 character varying(50),
    comment4 character varying(50)
);


ALTER TABLE public.bioanalis_golotur OWNER TO postgres;

--
-- Name: bioanalis_krevet; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bioanalis_krevet (
    myear dmsmallint_nn NOT NULL,
    vesselcode character varying(5) NOT NULL,
    numsurvey dmsmallint_nn NOT NULL,
    numstn dminteger_nn NOT NULL,
    numstrat dmsmallint NOT NULL,
    speciescode dmsmallint_nn NOT NULL,
    numspec dmsmallint_nn NOT NULL,
    lkarapax dmdouble,
    mlength dmdouble,
    weight dmdouble,
    moltingst character varying(1),
    sex character varying(1),
    eggs character varying(3),
    gonad character varying(1),
    sternal character varying(1),
    illnesscode dmsmallint,
    observcode dmsmallint,
    comment1 character varying(50),
    comment2 character varying(50),
    comment3 character varying(50),
    comment4 character varying(50)
);


ALTER TABLE public.bioanalis_krevet OWNER TO postgres;

--
-- Name: bioanalis_krill; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bioanalis_krill (
    myear dmsmallint_nn NOT NULL,
    vesselcode character varying(5) NOT NULL,
    numsurvey dmsmallint_nn NOT NULL,
    numstn dminteger_nn NOT NULL,
    speciescode dmsmallint_nn NOT NULL,
    numspec dmsmallint_nn NOT NULL,
    lkarapax dmdouble,
    weight dmdouble,
    sex character varying(1),
    stagepetasma character varying(1),
    condgenapert character varying(3),
    condamp character varying(1),
    spfform character varying(1),
    stagetelicum character varying(1),
    condspf character varying(1),
    spermball character varying(1),
    stageovary character varying(1),
    maturstage character varying(1),
    illnesscode dmsmallint,
    observcode dmsmallint,
    comment1 character varying(50),
    comment2 character varying(50),
    comment3 character varying(50),
    comment4 character varying(50)
);


ALTER TABLE public.bioanalis_krill OWNER TO postgres;

--
-- Name: bioanalis_molusk; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bioanalis_molusk (
    myear dmsmallint_nn NOT NULL,
    vesselcode character varying(5) NOT NULL,
    numsurvey dmsmallint_nn NOT NULL,
    numstn dminteger_nn NOT NULL,
    numstrat dmsmallint NOT NULL,
    speciescode dmsmallint_nn NOT NULL,
    numspec dmsmallint_nn NOT NULL,
    shellheight dmdouble,
    shellwidth dmdouble,
    weight dmsmallint,
    sex character varying(1),
    age dmsmallint,
    observcode dmsmallint,
    comment1 character varying(50),
    comment2 character varying(50),
    comment3 character varying(50),
    comment4 character varying(50)
);


ALTER TABLE public.bioanalis_molusk OWNER TO postgres;

--
-- Name: bioanalis_pelecipoda; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bioanalis_pelecipoda (
    myear dmsmallint_nn NOT NULL,
    vesselcode character varying(5) NOT NULL,
    numsurvey dmsmallint_nn NOT NULL,
    numstn dminteger_nn NOT NULL,
    numstrat dmsmallint NOT NULL,
    speciescode dmsmallint_nn NOT NULL,
    numspec dmsmallint_nn NOT NULL,
    shellheight dmdouble,
    shelllength dmdouble,
    bodywght dmsmallint,
    gonadwght dmsmallint,
    musclewght dmsmallint,
    sex character varying(1),
    age dmsmallint,
    gonadcolor character varying(1),
    illnesscode dmsmallint,
    observcode dmsmallint,
    comment1 character varying(50),
    comment2 character varying(50),
    comment3 character varying(50),
    comment4 character varying(50)
);


ALTER TABLE public.bioanalis_pelecipoda OWNER TO postgres;

--
-- Name: bioanalis_squid; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE bioanalis_squid (
    myear dmsmallint_nn NOT NULL,
    vesselcode character varying(5) NOT NULL,
    numsurvey dmsmallint_nn NOT NULL,
    numstn dminteger_nn NOT NULL,
    numstrat dmsmallint NOT NULL,
    speciescode dmsmallint_nn NOT NULL,
    numspec dmsmallint_nn NOT NULL,
    mlength dmsmallint,
    weight dmsmallint,
    sex character varying(1),
    stagemat character varying(1),
    substagemat character varying(1),
    mating character varying(1),
    stomach dmsmallint,
    observcode dmsmallint,
    comment1 character varying(50),
    comment2 character varying(50),
    comment3 character varying(50),
    comment4 character varying(50)
);


ALTER TABLE public.bioanalis_squid OWNER TO postgres;

--
-- Name: catch; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE catch (
    myear dmsmallint_nn NOT NULL,
    vesselcode character varying(5) NOT NULL,
    numsurvey dmsmallint_nn NOT NULL,
    numstn dminteger_nn NOT NULL,
    grup dmsmallint NOT NULL,
    speciescode dmsmallint_nn NOT NULL,
    measure dmsmallint,
    catch dmdouble,
    commcatch dmdouble,
    samplewght dmdouble,
    observcode dmsmallint,
    comment1 character varying(50),
    comment2 character varying(50),
    comment3 character varying(50),
    catchpromm dmsmallint,
    catchnonpromm dmsmallint,
    catchf dmsmallint,
    weightm dmdouble,
    weightf dmdouble,
    weightj dmdouble
);


ALTER TABLE public.catch OWNER TO postgres;

--
-- Name: gear_spr; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE gear_spr (
    gearcode dmsmallint_nn NOT NULL,
    mtype dmsmallint,
    name character varying(80),
    kf dmdouble,
    vertraskr dmdouble,
    gorizraskr dmdouble,
    sizecell dmdouble,
    selectresh dmsmallint,
    numbin dmsmallint,
    kf1 dmdouble,
    kf2 dmdouble,
    h dmdouble,
    nagivka dmsmallint,
    soblov dmdouble,
    lvaer dmdouble,
    kolkr1 dmsmallint,
    kolkr2 dmsmallint,
    numkr dmsmallint
);


ALTER TABLE public.gear_spr OWNER TO postgres;

--
-- Name: grunt_spr; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE grunt_spr (
    bottomcode dmsmallint_nn NOT NULL,
    name character varying(80),
    mtype character varying(20),
    size_mm character varying(20)
);


ALTER TABLE public.grunt_spr OWNER TO postgres;

--
-- Name: illness_spr; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE illness_spr (
    illnesscode dmsmallint_nn NOT NULL,
    mtype dmsmallint,
    name character varying(80),
    comment character varying(255)
);


ALTER TABLE public.illness_spr OWNER TO postgres;

--
-- Name: jurnalcatchstrat; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE jurnalcatchstrat (
    myear dmsmallint_nn NOT NULL,
    vesselcode character varying(5) NOT NULL,
    numsurvey dmsmallint_nn NOT NULL,
    numstn dminteger_nn NOT NULL,
    numstrat dmsmallint_nn NOT NULL,
    speciescode dmsmallint_nn NOT NULL,
    square dmsmallint,
    catchsht dmsmallint,
    catchgram dmsmallint
);


ALTER TABLE public.jurnalcatchstrat OWNER TO postgres;

--
-- Name: jurnalstrat; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE jurnalstrat (
    myear dmsmallint_nn NOT NULL,
    vesselcode character varying(5) NOT NULL,
    numsurvey dmsmallint_nn NOT NULL,
    numstn dminteger_nn NOT NULL,
    numstrat dmsmallint_nn NOT NULL,
    depthbeg dmdouble,
    depthend dmdouble,
    tbottom dmdouble,
    bottomcode dmsmallint,
    proc dmsmallint,
    bottomcode1 dmsmallint,
    proc1 dmsmallint
);


ALTER TABLE public.jurnalstrat OWNER TO postgres;

--
-- Name: observ_spr; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE observ_spr (
    observcode dmsmallint_nn NOT NULL,
    name character varying(50),
    placework character varying(80),
    qualification character varying(50)
);


ALTER TABLE public.observ_spr OWNER TO postgres;

--
-- Name: promer; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE promer (
    myear dmsmallint_nn NOT NULL,
    vesselcode character varying(5) NOT NULL,
    numsurvey dmsmallint_nn NOT NULL,
    numstn dminteger_nn NOT NULL,
    speciescode dmsmallint_nn NOT NULL,
    sex character varying(1) NOT NULL,
    sizeclass dmsmallint_nn NOT NULL,
    numb dmsmallint
);


ALTER TABLE public.promer OWNER TO postgres;

--
-- Name: species_spr; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE species_spr (
    speciescode dmsmallint_nn NOT NULL,
    namerus character varying(80),
    namelat character varying(80),
    grup character varying(80),
    m_order character varying(80),
    family character varying(80),
    minlength dmdouble,
    maxlength dmdouble,
    minweight dmdouble,
    maxweight dmdouble
);


ALTER TABLE public.species_spr OWNER TO postgres;

--
-- Name: stations; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE stations (
    myear dmsmallint_nn NOT NULL,
    vesselcode character varying(5) NOT NULL,
    numsurvey dmsmallint_nn NOT NULL,
    numstn dminteger_nn NOT NULL,
    typesurvey dmsmallint NOT NULL,
    numjurnalstn dminteger,
    nlov dmsmallint,
    gearcode dmsmallint,
    vtral dmdouble,
    datebegin character varying(11),
    timebegin character varying(6),
    latgradbeg dmsmallint,
    latminbeg dmdouble,
    longradbeg dmsmallint,
    lonminbeg dmdouble,
    depthbeg dmsmallint,
    dateend character varying(11),
    timeend character varying(6),
    latgradend dmsmallint,
    latminend dmdouble,
    longradend dmsmallint,
    lonminend dmdouble,
    depthend dmsmallint,
    depthtral dmsmallint,
    wirelength dmsmallint,
    nlovobr dmsmallint,
    bottomcode dmsmallint DEFAULT 0 NOT NULL,
    press dmsmallint,
    t dmdouble,
    vwind dmsmallint,
    rwind dmsmallint,
    wave dmsmallint,
    tsurface dmdouble,
    tbottom dmdouble,
    samplewght dmsmallint,
    observnum dmsmallint,
    cell dmsmallint,
    trapdist dmsmallint,
    formcatch dmsmallint,
    lcatch dmsmallint,
    wcatch dmsmallint,
    hcatch dmsmallint,
    nentr dmsmallint,
    kurs dmsmallint,
    observcode dmsmallint,
    ngrupspec dmsmallint,
    flagsgrup dminteger
);


ALTER TABLE public.stations OWNER TO postgres;

--
-- Name: vessel_spr; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE vessel_spr (
    vesselcode character varying(5) NOT NULL,
    name character varying(30),
    class character varying(10),
    port character varying(20),
    numbreg dminteger,
    hullno character varying(10),
    callsign character varying(5),
    myear dmsmallint,
    shipowner character varying(30),
    mlength dmdouble,
    maxlength dmdouble,
    midshipht dmdouble,
    freeboard dmdouble,
    middraft dmdouble,
    grt dmsmallint,
    nrt dmsmallint,
    dedweit dmsmallint,
    cargospace dmsmallint,
    numbtanks dmsmallint,
    engpower dmsmallint,
    enginetype character varying(20),
    cruisspeed dmsmallint,
    decwinch character varying(30),
    winchpower dmdouble,
    crew dmsmallint,
    namecapt character varying(30)
);


ALTER TABLE public.vessel_spr OWNER TO postgres;

--
-- Data for Name: bioanalis_crab; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY bioanalis_crab (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec, lkarapax, wkarapax, clawhight, weight, moltingst, sex, eggs, leglost, illnesscode, observcode, comment1, comment2, comment3, comment4, label) FROM stdin;
2000	000а	1	12	0	673	1	22222	71	14.800000000000001	138	6	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	12	0	673	2	22222	64	11.6	90	4	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	12	0	673	3	22222	79	13.199999999999999	190	6	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	14	0	673	1	22222	94	22.399999999999999	364	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	14	0	673	2	22222	58	9.3000000000000007	72	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	1	22222	74	15.199999999999999	152	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	2	22222	54	9	62	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	3	22222	44	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	4	22222	71	14.6	148	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	5	22222	45	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	6	22222	97	22.5	378	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	7	22222	52	7.5999999999999996	48	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	8	22222	94	20.600000000000001	324	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	9	22222	43	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	10	22222	43	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	11	22222	62	10	86	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	12	22222	45	22222	30	3	f	лв	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	13	22222	52	22222	46	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	14	22222	41	22222	24	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	15	22222	45	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	16	22222	41	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	17	22222	60	22222	66	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	18	22222	50	7.5	52	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	19	22222	55	9	64	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	20	22222	49	22222	42	6	f	лв	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	21	22222	73	16.100000000000001	150	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	22	22222	68	12	122	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	23	22222	43	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	24	22222	41	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	25	22222	53	8.1999999999999993	56	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	26	22222	62	10.300000000000001	86	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	27	22222	50	22222	42	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	28	22222	53	22222	48	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	29	22222	48	22222	40	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	30	22222	60	12.6	98	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	31	22222	42	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	32	22222	49	22222	40	6	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	33	22222	44	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	34	22222	45	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	35	22222	46	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	36	22222	39	22222	20	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	37	22222	40	22222	22	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	38	22222	43	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	39	22222	57	11.699999999999999	82	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	40	22222	46	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	41	22222	85	16	174	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	42	22222	42	7	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	43	22222	37	22222	20	6	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	44	22222	52	7.9000000000000004	52	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	45	22222	63	11	98	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	46	22222	47	22222	38	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	47	22222	42	22222	21	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	48	22222	46	22222	32	2	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	49	22222	44	6.2000000000000002	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	50	22222	48	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	51	22222	45	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	52	22222	46	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	53	22222	44	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	54	22222	53	22222	46	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	55	22222	47	22222	36	6	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	56	22222	46	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	57	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	58	22222	43	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	59	22222	56	22222	64	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	60	22222	47	7.2000000000000002	38	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	61	22222	41	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	62	22222	58	8.5	70	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	63	22222	46	22222	32	6	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	64	22222	47	22222	36	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	65	22222	61	10.9	90	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	66	22222	48	22222	36	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	67	22222	46	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	68	22222	49	22222	42	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	69	22222	46	22222	36	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	70	22222	44	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	71	22222	47	22222	36	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	72	22222	45	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	73	22222	45	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	74	22222	50	22222	42	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	75	22222	44	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	76	22222	48	22222	36	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	77	22222	41	6.2000000000000002	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	78	22222	74	16.199999999999999	174	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	79	22222	109	26.699999999999999	548	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	80	22222	74	15.9	144	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	81	22222	45	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	82	22222	60	12.300000000000001	90	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	83	22222	46	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	84	22222	46	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	85	22222	47	22222	34	6	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	86	22222	45	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	87	22222	45	6.2999999999999998	36	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	88	22222	44	6.5999999999999996	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	89	22222	56	8.6999999999999993	60	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	90	22222	50	22222	44	6	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	91	22222	47	7.2000000000000002	42	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	92	22222	42	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	93	22222	45	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	94	22222	72	16.600000000000001	162	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	95	22222	45	7	34	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	96	22222	41	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	97	22222	73	17.399999999999999	168	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	98	22222	45	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	99	22222	71	12.199999999999999	124	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	100	22222	49	22222	38	6	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	101	22222	43	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	102	22222	43	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	15	0	673	103	22222	46	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	1	22222	82	18.100000000000001	246	6	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	2	22222	65	11.6	110	6	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	3	22222	56	9.5999999999999996	70	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	4	22222	62	11.1	92	6	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	5	22222	56	8.8000000000000007	52	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	6	22222	80	18	202	4	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	7	22222	57	9.0999999999999996	70	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	8	22222	53	22222	52	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	9	22222	50	22222	42	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	10	22222	55	22222	56	3	f	лв	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	11	22222	55	22222	56	3	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	12	22222	47	22222	42	3	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	13	22222	52	22222	50	3	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	14	22222	56	22222	58	3	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	15	22222	53	22222	58	3	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	16	22222	49	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	17	22222	44	6.7000000000000002	34	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	18	22222	38	4.5	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	19	22222	43	6.2000000000000002	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	20	22222	49	22222	38	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	21	22222	69	12.1	122	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	22	22222	44	6.5	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	23	22222	51	22222	48	3	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	24	22222	43	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	25	22222	47	7.2999999999999998	44	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	26	22222	46	6.0999999999999996	34	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	27	22222	52	8.1999999999999993	50	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	28	22222	53	8.3000000000000007	54	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	29	22222	58	22222	66	3	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	30	22222	58	22222	64	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	31	22222	56	22222	56	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	32	22222	43	5.5999999999999996	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	33	22222	32	4.4000000000000004	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	34	22222	46	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	35	22222	47	22222	36	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	36	22222	51	22222	44	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	37	22222	48	22222	44	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	38	22222	45	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	39	22222	50	22222	42	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	40	22222	40	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	16	0	673	41	22222	41	22222	22	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	1	22222	50	22222	40	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	2	22222	71	12.300000000000001	136	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	3	22222	77	17.199999999999999	190	6	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	4	22222	64	11.6	98	6	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	5	22222	54	22222	56	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	6	22222	53	22222	52	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	7	22222	66	10.4	116	6	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	8	22222	58	22222	66	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	9	22222	44	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	10	22222	58	22222	66	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	11	22222	45	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	12	22222	44	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	13	22222	48	22222	40	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	14	22222	49	22222	42	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	17	0	673	15	22222	52	7.5999999999999996	50	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	18	0	673	1	22222	108	22	526	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	18	0	673	2	22222	77	17.100000000000001	202	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	19	0	673	1	22222	103	25.399999999999999	460	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	19	0	673	2	22222	47	22222	38	3	f	ял	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	19	0	673	3	22222	52	22222	50	3	f	ял	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	20	0	673	1	22222	84	19.199999999999999	254	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	20	0	673	2	22222	79	17	170	6	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	21	0	673	1	22222	81	18.100000000000001	186	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	21	0	673	2	22222	44	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	21	0	673	3	22222	55	22222	60	3	f	ял	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	21	0	673	4	22222	44	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	21	0	673	5	22222	48	8.0999999999999996	44	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	21	0	673	6	22222	49	8.0999999999999996	44	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	21	0	673	7	22222	47	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	21	0	673	8	22222	53	22222	46	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	21	0	673	9	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	1	22222	84	15.800000000000001	226	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	2	22222	85	14.5	178	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	3	22222	74	12.4	150	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	4	22222	71	11.800000000000001	132	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	5	22222	65	13.6	102	6	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	6	22222	48	22222	40	4	f	лв	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	7	22222	47	22222	36	4	f	лв	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	8	22222	42	22222	28	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	9	22222	48	22222	42	4	f	лв	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	10	22222	46	22222	34	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	11	22222	48	22222	40	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	12	22222	42	22222	30	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	13	22222	43	22222	30	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	14	22222	45	22222	34	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	15	22222	43	22222	30	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	16	22222	43	22222	30	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	17	22222	45	22222	26	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	18	22222	42	22222	28	4	f	лв	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	19	22222	49	22222	40	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	20	22222	47	22222	40	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	21	22222	47	22222	36	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	22	22222	43	22222	34	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	23	22222	43	22222	28	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	24	0	673	24	22222	44	22222	34	4	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	25	0	673	1	22222	46	22222	38	3	f	ир	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	29	0	673	1	22222	76	15.300000000000001	164	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	29	0	673	2	22222	82	17.800000000000001	182	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	29	0	673	3	22222	75	15.5	170	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	29	0	673	4	22222	75	16.5	144	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	29	0	673	5	22222	74	12.300000000000001	136	6	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	29	0	673	6	22222	31	22222	12	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	29	0	673	7	22222	28	22222	8	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	29	0	673	8	22222	22	3	5	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	30	0	673	1	22222	87	20	252	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	30	0	673	2	22222	90	19.300000000000001	284	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	30	0	673	3	22222	84	15.800000000000001	226	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	30	0	673	4	22222	76	14	164	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	30	0	673	5	22222	21	2.8999999999999999	3	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	30	0	673	6	22222	21	2.7000000000000002	3	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	31	0	673	1	22222	37	5.4000000000000004	18	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	32	0	673	46	22222	32	22222	12	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	32	0	673	47	22222	32	22222	10	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	32	0	673	48	22222	55	12	78	4	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	32	0	673	49	22222	76	22222	134	2	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	1	22222	33	4.5	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	2	22222	33	5.0999999999999996	14	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	3	22222	29	22222	10	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	4	22222	31	22222	10	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	5	22222	30	4.5999999999999996	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	6	22222	27	4.0999999999999996	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	7	22222	23	3.5	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	8	22222	29	4.2000000000000002	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	9	22222	29	22222	10	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	10	22222	25	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	11	22222	25	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	12	22222	30	4.5	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	13	22222	29	22222	8	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	14	22222	24	22222	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	15	22222	23	3.5	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	56	22222	39	3.2000000000000002	22	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	16	22222	21	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	17	22222	25	4	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	18	22222	34	22222	14	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	19	22222	23	3.7999999999999998	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	20	22222	22	3.6000000000000001	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	21	22222	21	3.2000000000000002	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	22	22222	25	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	23	22222	25	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	24	22222	24	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	25	22222	30	22222	10	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	26	22222	23	3.2999999999999998	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	27	22222	21	22222	3	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	28	22222	25	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	29	22222	22	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	30	22222	23	3.2999999999999998	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	31	22222	25	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	32	22222	22	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	33	22222	25	4	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	34	22222	29	22222	8	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	35	22222	22	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	36	22222	24	3.7000000000000002	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	37	22222	22	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	38	22222	25	3.6000000000000001	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	39	22222	24	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	40	22222	30	22222	12	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	41	22222	23	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	42	22222	21	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	43	22222	23	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	44	22222	27	3.7999999999999998	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	45	22222	29	4.0999999999999996	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	46	22222	23	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	47	22222	23	3.2000000000000002	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	48	22222	21	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	49	22222	28	4.2000000000000002	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	50	22222	28	4.0999999999999996	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	51	22222	42	6.5	28	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	52	22222	29	22222	10	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	53	22222	24	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	54	22222	43	22222	26	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	55	22222	22	3.3999999999999999	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	56	22222	21	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	57	22222	23	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	58	22222	22	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	59	22222	30	4.4000000000000004	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	60	22222	24	3.7000000000000002	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	61	22222	20	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	62	22222	21	3.2999999999999998	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	63	22222	24	3.3999999999999999	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	64	22222	20	3	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	65	22222	23	3.5	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	66	22222	31	22222	10	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	67	22222	21	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	68	22222	41	22222	24	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	69	22222	20	4	22222	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	70	22222	23	3.5	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	71	22222	26	22222	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	72	22222	22	3.3999999999999999	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	73	22222	30	4.2000000000000002	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	74	22222	25	3.6000000000000001	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	75	22222	22	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	76	22222	24	3.7000000000000002	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	77	22222	25	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	78	22222	31	4.5999999999999996	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	79	22222	23	3.5	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	80	22222	23	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	81	22222	25	3.2999999999999998	22222	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	82	22222	22	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	83	22222	25	3.7999999999999998	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	84	22222	25	3.6000000000000001	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	85	22222	30	4.4000000000000004	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	86	22222	24	3.5	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	87	22222	29	4.2999999999999998	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	88	22222	21	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	89	22222	22	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	90	22222	22	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	91	22222	24	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	92	22222	22	3.2000000000000002	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	93	22222	22	3.1000000000000001	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	94	22222	23	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	95	22222	22	3.1000000000000001	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	96	22222	20	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	97	22222	22	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	98	22222	25	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	99	22222	24	3.5	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	100	22222	23	3.5	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	101	22222	34	5.2999999999999998	14	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	102	22222	23	3	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	103	22222	21	2.8999999999999999	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	104	22222	21	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	105	22222	24	3.3999999999999999	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	106	22222	24	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	107	22222	20	2.8999999999999999	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	108	22222	21	22222	22222	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	109	22222	23	2.2000000000000002	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	110	22222	30	22222	10	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	111	22222	25	3.6000000000000001	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	112	22222	27	4	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	113	22222	26	22222	7	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	114	22222	24	3.5	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	115	22222	21	22222	4	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	116	22222	24	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	117	22222	21	2.8999999999999999	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	118	22222	23	3.5	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	119	22222	22	3.2000000000000002	4	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	120	22222	22	3.2999999999999998	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	121	22222	19	2.5	2	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	122	22222	24	3.2000000000000002	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	33	0	673	123	22222	25	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	1	22222	40	5.2999999999999998	23	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	2	22222	44	7	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	3	22222	43	7.2000000000000002	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	4	22222	38	6.2000000000000002	25	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	5	22222	44	6.5	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	6	22222	43	6.5999999999999996	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	7	22222	42	5.2999999999999998	29	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	8	22222	36	5.5	18	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	9	22222	37	5.2999999999999998	18	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	10	22222	30	4.2999999999999998	11	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	11	22222	23	22222	5	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	12	22222	34	5.2000000000000002	19	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	13	22222	35	22222	15	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	14	22222	37	5.5999999999999996	19	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	15	22222	33	5.2000000000000002	16	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	16	22222	35	4.7000000000000002	18	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	17	22222	46	6.9000000000000004	36	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	18	22222	38	22222	21	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	19	22222	27	3.7999999999999998	8	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	20	22222	32	4.0999999999999996	12	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	21	22222	33	5	15	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	22	22222	31	4.4000000000000004	13	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	23	22222	29	4	10	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	24	22222	38	22222	19	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	25	22222	24	6.4000000000000004	6	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	26	22222	35	5	17	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	27	22222	30	4.2000000000000002	12	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	28	22222	43	6.5	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	29	22222	15	22222	2	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	30	22222	42	6.0999999999999996	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	31	22222	32	22222	11	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	32	22222	16	22222	2	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	33	22222	28	4	9	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	34	22222	26	22222	8	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	35	22222	21	3	4	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	36	22222	20	3.7000000000000002	4	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	37	22222	31	4	12	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	38	22222	23	22222	5	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	39	22222	25	3.2000000000000002	7	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	40	22222	28	4	8	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	41	22222	32	22222	11	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	42	22222	27	3.6000000000000001	8	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	43	22222	23	22222	4	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	44	22222	31	4.7999999999999998	11	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	45	22222	20	3	3	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	46	22222	31	22222	11	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	47	22222	31	4.5	11	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	48	22222	28	22222	7	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	49	22222	37	5.5999999999999996	18	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	50	22222	43	5.5999999999999996	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	51	22222	25	2.7999999999999998	5	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	52	22222	35	22222	15	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	53	22222	33	22222	12	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	54	22222	21	22222	3	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	55	22222	45	2.7999999999999998	35	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	57	22222	27	3.7999999999999998	9	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	58	22222	32	4.5	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	59	22222	25	3.6000000000000001	7	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	60	22222	21	3	4	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	61	22222	24	22222	5	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	62	22222	23	2.8999999999999999	4	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	63	22222	23	3	5	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	64	22222	32	22222	13	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	65	22222	25	3.5	6	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	66	22222	21	22222	5	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	67	22222	34	5.2000000000000002	18	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	68	22222	30	4.2000000000000002	13	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	69	22222	30	22222	10	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	70	22222	38	5.2000000000000002	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	71	22222	25	3.6000000000000001	9	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	72	22222	33	22222	13	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	73	22222	46	7.5999999999999996	40	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	74	22222	33	5	16	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	75	22222	35	22222	15	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	76	22222	27	22222	9	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	77	22222	22	2.7999999999999998	4	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	78	22222	39	5	21	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	79	22222	35	4.7000000000000002	15	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	80	22222	32	4.2999999999999998	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	81	22222	38	22222	18	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	82	22222	27	4	8	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	83	22222	27	22222	8	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	84	22222	22	3	3	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	85	22222	30	4.4000000000000004	10	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	86	22222	19	2.3999999999999999	3	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	87	22222	21	22222	5	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	88	22222	27	3.2999999999999998	8	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	89	22222	31	4.7999999999999998	13	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	90	22222	34	5	16	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	91	22222	30	22222	10	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	92	22222	23	3.5	5	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	93	22222	32	4.7000000000000002	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	94	22222	26	22222	5	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	95	22222	28	22222	8	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	96	22222	26	3.6000000000000001	8	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	97	22222	19	2.6000000000000001	3	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	98	22222	33	5	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	99	22222	31	4.2000000000000002	12	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	100	22222	30	4.0999999999999996	11	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	101	22222	22	3	5	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	102	22222	27	4	9	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	103	22222	33	22222	14	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	104	22222	33	22222	12	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	105	22222	30	4	12	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	106	22222	27	22222	8	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	107	22222	31	22222	11	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	108	22222	20	2.7000000000000002	4	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	109	22222	22	2.7999999999999998	4	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	110	22222	33	4.7999999999999998	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	111	22222	23	22222	5	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	112	22222	29	4	11	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	113	22222	34	4.5999999999999996	17	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	114	22222	35	5.2000000000000002	17	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	115	22222	38	5.0999999999999996	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	116	22222	35	22222	15	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	117	22222	25	3.2000000000000002	6	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	118	22222	31	4.4000000000000004	12	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	119	22222	17	3.8999999999999999	3	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	120	22222	44	5.7999999999999998	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	121	22222	24	22222	7	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	122	22222	22	3.2000000000000002	4	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	123	22222	21	2.8999999999999999	3	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	124	22222	25	3	6	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	125	22222	35	5.2000000000000002	16	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	126	22222	33	4.2000000000000002	12	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	127	22222	30	4	11	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	128	22222	28	22222	8	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	129	22222	42	5.5999999999999996	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	130	22222	34	4.5999999999999996	17	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	131	22222	20	2.7000000000000002	4	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	132	22222	29	4	9	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	133	22222	31	4.5	12	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	134	22222	41	6	29	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	135	22222	32	4.7000000000000002	15	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	136	22222	37	5.5	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	137	22222	29	4.0999999999999996	9	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	138	22222	25	3.1000000000000001	5	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	139	22222	26	3.5	8	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	140	22222	37	5.4000000000000004	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	141	22222	19	2.5	3	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	142	22222	28	22222	8	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	143	22222	30	3.2000000000000002	10	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	144	22222	19	22222	3	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	145	22222	23	22222	5	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	146	22222	23	3.2000000000000002	7	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	147	22222	21	22222	5	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	148	22222	33	4.7999999999999998	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	149	22222	35	22222	16	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	34	0	673	150	22222	31	4.9000000000000004	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	1	22222	37	22222	18	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	4	22222	33	22222	14	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	5	22222	46	7.5999999999999996	38	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	10	22222	37	22222	20	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	11	22222	33	5.0999999999999996	22222	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	12	22222	36	22222	18	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	13	22222	40	6.2999999999999998	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	15	22222	29	4.4000000000000004	10	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	17	22222	40	6.4000000000000004	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	18	22222	39	6.4000000000000004	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	19	22222	46	8.9000000000000004	40	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	22	22222	46	7.5999999999999996	40	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	23	22222	46	7.4000000000000004	42	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	26	22222	43	6.7000000000000002	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	33	22222	35	5.2999999999999998	16	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	34	22222	38	5.9000000000000004	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	35	22222	35	22222	16	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	37	22222	33	5.5	16	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	39	22222	31	4.9000000000000004	12	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	40	22222	47	8.6999999999999993	42	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	42	22222	39	6.0999999999999996	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	46	22222	42	22222	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	50	22222	39	6	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	54	22222	34	5.5999999999999996	16	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	55	22222	35	6.2000000000000002	22	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	57	22222	28	4.2000000000000002	8	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	59	22222	30	4.7000000000000002	12	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	62	22222	46	7.4000000000000004	35	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	66	22222	41	6.2999999999999998	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	77	22222	30	22222	8	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	82	22222	34	5.2999999999999998	16	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	88	22222	46	8	38	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	92	22222	47	7.2000000000000002	40	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	95	22222	38	5.7000000000000002	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	97	22222	30	5	12	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	98	22222	33	22222	12	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	99	22222	33	5.4000000000000004	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	102	22222	38	22222	18	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	104	22222	38	22222	18	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	105	22222	33	22222	12	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	109	22222	45	8	38	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	110	22222	40	6.2000000000000002	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	111	22222	49	8.8000000000000007	48	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	112	22222	47	8	42	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	113	22222	44	6.5999999999999996	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	118	22222	43	22222	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	119	22222	43	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	120	22222	24	22222	4	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	123	22222	47	7.5999999999999996	40	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	128	22222	34	22222	14	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	130	22222	33	22222	14	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	132	22222	35	4.7000000000000002	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	139	22222	39	6	22	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	141	22222	39	5.7999999999999998	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	147	22222	43	6.7000000000000002	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	148	22222	32	22222	12	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	35	0	673	149	22222	33	5.0999999999999996	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	1	22222	34	22222	14	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	2	22222	31	22222	10	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	3	22222	36	22222	17	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	6	22222	28	22222	8	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	14	22222	42	22222	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	16	22222	30	22222	10	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	21	22222	40	22222	23	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	26	22222	30	22222	10	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	28	22222	31	22222	11	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	32	22222	30	22222	9	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	37	22222	29	22222	9	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	47	22222	40	22222	23	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	51	22222	31	22222	11	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	52	22222	36	22222	17	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	56	22222	28	22222	8	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	59	22222	50	22222	44	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	68	22222	31	22222	10	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	69	22222	30	22222	9	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	70	22222	33	22222	13	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	71	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	72	22222	31	22222	11	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	76	22222	26	22222	6	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	85	22222	29	22222	9	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	107	22222	30	22222	10	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	36	0	673	109	22222	35	22222	16	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	1	22222	48	7.4000000000000004	44	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	2	22222	53	8.5	52	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	3	22222	43	6.5999999999999996	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	4	22222	28	4	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	5	22222	50	6.9000000000000004	46	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	6	22222	44	6.4000000000000004	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	7	22222	29	4.2999999999999998	10	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	8	22222	49	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	9	22222	47	8.5	42	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	10	22222	35	5.0999999999999996	16	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	11	22222	49	7.7999999999999998	46	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	12	22222	30	4.2999999999999998	10	1	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	13	22222	25	3.5	6	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	14	22222	31	4.2999999999999998	10	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	15	22222	26	3.5	8	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	16	22222	39	22222	22	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	17	22222	28	3.8999999999999999	8	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	18	22222	30	4.2000000000000002	10	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	19	22222	33	4.7000000000000002	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	20	22222	45	7.4000000000000004	36	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	21	22222	42	6.2000000000000002	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	22	22222	30	4.5	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	23	22222	41	5.5	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	24	22222	36	5	18	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	25	22222	27	4	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	26	22222	42	6.4000000000000004	30	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	27	22222	28	4	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	28	22222	31	4.0999999999999996	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	29	22222	44	4.9000000000000004	28	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	30	22222	41	6.2000000000000002	28	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	31	22222	31	4	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	32	22222	50	7.2000000000000002	38	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	33	22222	32	4.7000000000000002	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	34	22222	45	7	30	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	35	22222	32	4.5	14	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	36	22222	43	6.9000000000000004	30	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	37	22222	41	5.5	24	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	38	22222	55	9.8000000000000007	68	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	39	22222	43	6.7999999999999998	30	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	40	22222	39	22222	22	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	41	22222	31	4.2000000000000002	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	42	22222	39	5	22	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	43	22222	33	5.2000000000000002	14	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	44	22222	44	6.5	30	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	45	22222	38	6	20	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	46	22222	30	4.0999999999999996	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	47	22222	28	3.5	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	48	22222	33	5	14	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	49	22222	46	6.5999999999999996	34	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	50	22222	43	6.0999999999999996	28	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	51	22222	44	7	36	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	52	22222	34	22222	14	6	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	53	22222	31	4.5	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	54	22222	33	22222	14	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	55	22222	31	4.4000000000000004	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	56	22222	28	3.8999999999999999	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	57	22222	31	4.2999999999999998	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	58	22222	28	4	22222	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	59	22222	30	3.5	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	60	22222	29	3.8999999999999999	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	61	22222	40	5.7999999999999998	24	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	62	22222	29	4	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	63	22222	25	3.5	6	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	64	22222	28	3.7999999999999998	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	65	22222	30	4.2000000000000002	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	37	0	673	66	22222	28	3.8999999999999999	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	1	22222	38	5.7000000000000002	22	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	2	22222	48	6.9000000000000004	36	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	3	22222	38	5.7000000000000002	22	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	4	22222	37	5.2999999999999998	20	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	5	22222	46	22222	22222	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	6	22222	33	4.7000000000000002	14	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	7	22222	34	5	16	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	8	22222	32	4.7999999999999998	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	9	22222	50	7.5	46	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	10	22222	40	6.2999999999999998	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	11	22222	29	22222	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	12	22222	30	4.5	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	13	22222	29	4.2000000000000002	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	14	22222	37	5.4000000000000004	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	15	22222	30	4.2000000000000002	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	16	22222	32	4.2999999999999998	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	38	0	673	17	22222	27	3.7000000000000002	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	1	22222	43	22222	29	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	2	22222	30	22222	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	3	22222	43	22222	29	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	5	22222	31	22222	11	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	6	22222	44	22222	31	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	7	22222	37	22222	19	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	8	22222	38	22222	20	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	9	22222	31	22222	11	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	11	22222	39	22222	22	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	12	22222	44	22222	31	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	13	22222	31	22222	11	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	14	22222	40	22222	23	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	15	22222	40	22222	24	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	17	22222	30	22222	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	18	22222	37	22222	19	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	19	22222	37	22222	19	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	20	22222	29	22222	9	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	21	22222	34	22222	14	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	22	22222	33	22222	14	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	23	22222	30	22222	10	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	24	22222	33	22222	13	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	25	22222	38	22222	20	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	26	22222	51	22222	47	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	27	22222	44	22222	31	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	28	22222	46	22222	35	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	33	22222	33	22222	13	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	35	22222	34	22222	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	36	22222	30	22222	9	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	37	22222	38	22222	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	40	0	673	38	22222	29	22222	8	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	41	0	673	1	22222	37	22222	18	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	41	0	673	2	22222	39	6.5	22	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	41	0	673	3	22222	44	6	31	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	41	0	673	4	22222	31	4.5	11	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	41	0	673	5	22222	33	4.9000000000000004	13	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	41	0	673	6	22222	21	22222	3	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	41	0	673	9	22222	32	5	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	41	0	673	10	22222	28	22222	8	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	42	0	673	1	22222	48	8	44	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	42	0	673	2	22222	44	22222	32	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	42	0	673	3	22222	84	15.6	22222	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	1	22222	48	8.3000000000000007	44	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	2	22222	45	7	38	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	3	22222	39	5.5	25	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	4	22222	41	22222	26	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	5	22222	42	22222	25	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	6	22222	43	22222	26	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	7	22222	42	22222	25	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	8	22222	42	22222	25	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	9	22222	48	8.4000000000000004	45	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	10	22222	34	22222	13	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	11	22222	41	22222	25	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	12	22222	31	22222	11	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	13	22222	44	7	33	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	14	22222	49	7.7999999999999998	47	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	15	22222	42	6	27	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	16	22222	35	22222	16	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	17	22222	32	4.0999999999999996	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	18	22222	40	22222	24	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	19	22222	41	22222	26	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	20	22222	41	22222	24	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	21	22222	42	6.7999999999999998	30	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	22	22222	34	22222	15	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	23	22222	30	4.4000000000000004	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	24	22222	36	5.5999999999999996	19	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	25	22222	41	5.5999999999999996	28	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	26	22222	53	9.4000000000000004	62	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	27	22222	44	6.5	34	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	28	22222	32	4.5999999999999996	13	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	29	22222	30	22222	21	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	30	22222	30	4.4000000000000004	11	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	31	22222	45	6.2000000000000002	33	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	32	22222	36	5.7999999999999998	38	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	33	22222	47	7.2000000000000002	40	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	34	22222	53	8	57	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	35	22222	53	8.5	58	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	36	22222	43	22222	30	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	37	22222	33	22222	13	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	38	22222	36	22222	17	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	39	22222	35	5.0999999999999996	17	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	40	22222	44	8.0999999999999996	36	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	41	22222	40	22222	25	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	42	22222	33	4.5999999999999996	14	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	43	22222	41	22222	25	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	44	22222	42	6.2999999999999998	28	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	45	22222	47	7.7999999999999998	41	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	46	22222	46	22222	35	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	47	22222	51	8.4000000000000004	52	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	48	22222	41	22222	27	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	49	22222	47	7.5	45	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	50	22222	45	7	34	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	51	22222	40	6.2000000000000002	25	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	52	22222	41	22222	24	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	53	22222	44	7	38	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	54	22222	38	5.5	21	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	55	22222	36	5	20	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	56	22222	43	22222	26	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	57	22222	32	4.5999999999999996	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	58	22222	29	22222	11	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	59	22222	25	22222	6	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	60	22222	33	22222	14	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	61	22222	37	22222	19	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	62	22222	35	22222	14	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	63	22222	42	6.5	28	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	64	22222	44	7	35	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	65	22222	40	22222	21	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	66	22222	43	6.9000000000000004	28	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	67	22222	28	22222	9	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	68	22222	44	22222	30	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	69	22222	38	6	23	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	70	22222	32	3.8999999999999999	13	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	71	22222	33	22222	12	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	72	22222	32	22222	12	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	73	22222	32	22222	13	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	74	22222	39	22222	22	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	75	22222	48	22222	33	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	76	22222	45	7	38	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	77	22222	36	22222	17	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	78	22222	44	22222	29	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	79	22222	45	7.0999999999999996	38	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	80	22222	41	6.4000000000000004	30	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	81	22222	36	5.7999999999999998	22	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	82	22222	40	22222	27	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	83	22222	45	22222	33	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	84	22222	39	6	22	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	85	22222	43	6.5999999999999996	28	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	86	22222	38	5.9000000000000004	22	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	87	22222	39	5.5	23	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	88	22222	36	5.4000000000000004	17	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	89	22222	41	6.2999999999999998	30	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	90	22222	50	7.7999999999999998	48	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	91	22222	43	22222	27	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	92	22222	53	9.1999999999999993	62	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	93	22222	43	6.4000000000000004	31	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	94	22222	42	22222	26	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	95	22222	42	4.7999999999999998	14	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	96	22222	32	4.4000000000000004	14	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	97	22222	49	7.4000000000000004	44	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	98	22222	46	22222	38	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	99	22222	44	7.2000000000000002	35	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	100	22222	45	6.9000000000000004	32	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	101	22222	39	5.7999999999999998	22	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	102	22222	41	22222	25	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	103	22222	34	4.5999999999999996	15	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	104	22222	45	6.7999999999999998	37	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	105	22222	42	6.7000000000000002	30	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	106	22222	37	5.5	20	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	107	22222	43	6.5	32	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	108	22222	44	22222	32	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	109	22222	40	6	24	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	110	22222	42	7.2000000000000002	28	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	111	22222	43	22222	26	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	112	22222	45	6.5	36	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	113	22222	42	6.2999999999999998	31	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	114	22222	47	7.4000000000000004	42	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	115	22222	30	22222	11	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	116	22222	38	5.7999999999999998	22	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	117	22222	37	5.5	18	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	118	22222	30	22222	12	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	119	22222	34	22222	14	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	120	22222	26	22222	8	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	121	22222	31	22222	10	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	122	22222	32	4.5	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	123	22222	34	5.2000000000000002	17	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	124	22222	55	10	77	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	125	22222	52	10.199999999999999	57	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	126	22222	38	22222	18	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	127	22222	33	22222	12	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	128	22222	38	5.4000000000000004	20	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	129	22222	32	22222	12	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	130	22222	39	22222	21	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	131	22222	46	6.9000000000000004	36	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	132	22222	39	5.7999999999999998	26	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	133	22222	43	6.2000000000000002	31	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	134	22222	35	5.7999999999999998	23	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	135	22222	40	6.2999999999999998	26	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	136	22222	35	22222	16	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	137	22222	31	4.0999999999999996	11	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	138	22222	33	22222	13	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	139	22222	36	5.4000000000000004	18	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	140	22222	40	22222	25	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	141	22222	34	4.9000000000000004	14	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	142	22222	43	6.2999999999999998	13	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	143	22222	42	22222	28	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	144	22222	29	4.2000000000000002	10	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	145	22222	34	5	17	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	146	22222	33	22222	13	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	147	22222	35	4.4000000000000004	17	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	148	22222	43	6.7999999999999998	30	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	149	22222	41	22222	22	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	46	0	673	150	22222	39	22222	21	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	1	22222	46	22222	36	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	2	22222	43	22222	26	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	3	22222	42	22222	26	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	4	22222	34	22222	14	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	5	22222	43	22222	28	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	6	22222	42	22222	26	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	7	22222	43	6.5	30	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	8	22222	41	6.0999999999999996	28	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	9	22222	40	6.7999999999999998	26	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	10	22222	37	5.2000000000000002	20	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	11	22222	36	5.4000000000000004	20	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	12	22222	30	5.2000000000000002	14	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	13	22222	40	6.2000000000000002	24	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	14	22222	40	22222	24	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	15	22222	43	8.1999999999999993	32	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	16	22222	33	22222	13	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	17	22222	29	4.2999999999999998	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	18	22222	28	22222	8	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	19	22222	48	8	38	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	20	22222	43	7.5999999999999996	30	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	21	22222	35	22222	16	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	22	22222	39	5.7999999999999998	24	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	23	22222	35	5.2000000000000002	18	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	24	22222	33	22222	16	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	25	22222	30	22222	12	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	26	22222	31	4.4000000000000004	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	27	22222	35	22222	18	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	28	22222	37	22222	20	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	29	22222	40	22222	24	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	30	22222	36	22222	16	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	31	22222	40	22222	24	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	32	22222	33	22222	14	5	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	33	22222	46	7	38	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	34	22222	39	6.2000000000000002	26	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	35	22222	28	3.8999999999999999	12	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	47	0	673	36	22222	38	5.5	22	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	1	22222	43	22222	30	3	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	2	22222	29	4	10	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	4	22222	39	6.2999999999999998	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	5	22222	35	4.5999999999999996	16	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	8	22222	31	4.4000000000000004	12	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	11	22222	33	22222	12	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	12	22222	28	3.8999999999999999	10	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	13	22222	41	6	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	14	22222	42	6.5	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	15	22222	52	8.5999999999999996	52	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	17	22222	65	14.199999999999999	98	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	18	22222	52	7.9000000000000004	54	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	20	22222	38	5.7000000000000002	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	22	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	24	22222	37	5.5	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	26	22222	40	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	27	22222	27	22222	8	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	28	22222	42	6.2000000000000002	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	29	22222	43	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	32	22222	40	22222	20	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	33	22222	35	5.5	16	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	34	22222	33	22222	14	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	35	22222	46	87	38	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	36	22222	37	22222	18	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	38	22222	41	5.7999999999999998	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	39	22222	43	6.5999999999999996	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	42	22222	38	22222	20	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	43	22222	34	22222	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	44	22222	34	5.2000000000000002	14	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	45	22222	38	5.4000000000000004	22	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	48	0	673	48	22222	38	5.5999999999999996	22	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	1	22222	59	12.6	91	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	4	22222	62	22222	80	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	6	22222	42	5.7999999999999998	31	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	7	22222	45	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	8	22222	40	22222	22	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	9	22222	41	6.0999999999999996	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	10	22222	43	6.2000000000000002	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	11	22222	39	5.9000000000000004	21	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	13	22222	50	22222	41	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	14	22222	38	22222	21	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	15	22222	60	10.4	86	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	16	22222	40	22222	25	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	17	22222	42	22222	25	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	18	22222	47	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	19	22222	38	22222	21	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	20	22222	38	22222	19	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	21	22222	39	6.2000000000000002	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	22	22222	39	22222	22	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	23	22222	44	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	24	22222	50	22222	45	3	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	25	22222	51	9.1999999999999993	58	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	26	22222	71	14.699999999999999	144	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	28	22222	42	22222	28	3	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	29	22222	37	22222	19	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	30	22222	43	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	32	22222	41	22222	25	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	33	22222	38	5.9000000000000004	23	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	34	22222	45	6.9000000000000004	37	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	35	22222	49	22222	40	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	36	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	37	22222	42	6.4000000000000004	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	38	22222	43	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	39	22222	38	22222	23	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	40	22222	58	8.8000000000000007	64	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	41	22222	40	22222	25	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	42	22222	41	5.7000000000000002	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	44	22222	46	22222	31	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	45	22222	47	7.2999999999999998	40	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	46	22222	42	6.5999999999999996	29	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	47	22222	42	22222	27	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	48	22222	44	7	31	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	49	22222	37	22222	17	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	50	22222	37	22222	20	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	51	22222	42	6.2000000000000002	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	52	22222	45	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	53	22222	41	6	27	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	55	22222	42	22222	28	3	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	56	22222	54	8.8000000000000007	62	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	57	22222	42	6.4000000000000004	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	58	22222	45	22222	34	3	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	59	22222	41	22222	25	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	60	22222	39	5.9000000000000004	25	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	61	22222	42	6.5999999999999996	31	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	62	22222	43	22222	27	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	63	22222	42	6.2000000000000002	27	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	64	22222	36	5.5999999999999996	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	66	22222	58	22222	55	3	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	67	22222	51	7.5999999999999996	50	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	69	22222	55	22222	54	3	f	иг	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	70	22222	39	5.7999999999999998	23	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	71	22222	41	22222	25	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	72	22222	37	22222	19	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	74	22222	45	7.0999999999999996	37	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	75	22222	46	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	76	22222	48	7.2999999999999998	43	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	77	22222	40	6	22	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	79	22222	37	5.7999999999999998	19	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	80	22222	36	5.2999999999999998	16	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	81	22222	42	6.7000000000000002	31	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	82	22222	52	22222	44	2	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	83	22222	41	6.5999999999999996	42	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	84	22222	52	22222	49	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	85	22222	51	9	53	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	86	22222	42	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	87	22222	40	22222	22	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	88	22222	37	5.4000000000000004	19	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	89	22222	57	22222	62	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	90	22222	39	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	91	22222	41	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	92	22222	27	22222	8	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	93	22222	37	22222	19	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	94	22222	37	22222	20	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	95	22222	39	6.0999999999999996	27	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	96	22222	41	22222	22	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	97	22222	39	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	98	22222	37	22222	17	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	99	22222	40	5.9000000000000004	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	100	22222	42	22222	27	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	101	22222	29	22222	10	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	102	22222	40	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	103	22222	38	22222	19	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	104	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	105	22222	37	22222	18	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	107	22222	38	22222	22	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	108	22222	44	22222	29	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	109	22222	36	22222	19	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	110	22222	40	22222	23	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	111	22222	37	5.7000000000000002	19	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	112	22222	38	5.5	23	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	113	22222	41	6.2000000000000002	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	114	22222	42	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	49	0	673	115	22222	39	22222	19	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	1	22222	55	8.6999999999999993	66	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	2	22222	43	6	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	3	22222	45	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	4	22222	43	6.5	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	5	22222	60	14.4	94	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	6	22222	51	8.4000000000000004	52	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	7	22222	66	12.800000000000001	108	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	8	22222	50	7.2000000000000002	48	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	9	22222	41	6.5	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	10	22222	48	22222	40	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	11	22222	42	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	12	22222	48	22222	36	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	13	22222	41	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	14	22222	43	6.7000000000000002	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	15	22222	44	6.4000000000000004	33	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	17	22222	48	22222	38	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	18	22222	44	7	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	19	22222	45	6.9000000000000004	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	20	22222	42	6.5	27	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	21	22222	40	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	22	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	23	22222	43	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	24	22222	47	7.4000000000000004	42	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	25	22222	37	5.5	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	26	22222	53	22222	52	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	27	22222	44	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	28	22222	48	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	29	22222	42	6.2999999999999998	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	30	22222	53	8.8000000000000007	58	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	31	22222	45	22222	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	32	22222	38	22222	22	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	33	22222	36	22222	18	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	34	22222	44	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	108	22222	46	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	35	22222	44	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	36	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	37	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	38	22222	46	6.7999999999999998	38	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	39	22222	45	7.5999999999999996	38	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	41	22222	48	7.4000000000000004	42	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	42	22222	44	6.5	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	43	22222	47	22222	38	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	44	22222	42	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	45	22222	38	22222	20	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	46	22222	46	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	47	22222	42	6	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	48	22222	44	6.7000000000000002	36	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	49	22222	41	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	50	22222	44	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	51	22222	44	7.0999999999999996	36	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	52	22222	48	7.7000000000000002	42	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	53	22222	50	9.4000000000000004	48	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	54	22222	38	22222	20	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	55	22222	41	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	56	22222	42	6.5	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	57	22222	37	5.7000000000000002	44	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	58	22222	53	7.7999999999999998	48	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	59	22222	39	5.7000000000000002	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	60	22222	39	22222	20	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	61	22222	49	22222	42	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	63	22222	44	6.5	34	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	64	22222	51	7.7999999999999998	48	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	65	22222	46	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	66	22222	40	5.5999999999999996	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	67	22222	44	7	34	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	68	22222	44	6.7999999999999998	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	69	22222	44	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	70	22222	39	5.7999999999999998	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	71	22222	40	6	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	72	22222	42	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	73	22222	37	5.0999999999999996	18	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	74	22222	44	6.7999999999999998	34	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	75	22222	41	6	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	76	22222	43	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	77	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	78	22222	39	5.5	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	79	22222	40	6	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	80	22222	38	22222	20	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	81	22222	42	7	34	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	82	22222	39	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	83	22222	38	5.5	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	84	22222	41	6	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	85	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	86	22222	42	7.5	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	87	22222	40	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	88	22222	47	22222	36	4	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	89	22222	44	6.2000000000000002	34	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	90	22222	40	6.2999999999999998	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	91	22222	37	5.2000000000000002	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	92	22222	28	3	3	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	93	22222	45	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	94	22222	53	8.1999999999999993	54	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	95	22222	45	7.5	40	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	96	22222	43	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	97	22222	44	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	98	22222	43	5	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	99	22222	46	7.2000000000000002	40	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	100	22222	43	7	34	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	101	22222	42	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	102	22222	41	22222	20	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	103	22222	48	7.4000000000000004	36	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	104	22222	38	22222	20	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	105	22222	40	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	106	22222	48	22222	42	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	107	22222	41	22222	22	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	108	22222	40	22222	22	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	109	22222	36	22222	16	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	110	22222	47	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	111	22222	22	2.8999999999999999	6	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	112	22222	45	22222	36	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	113	22222	42	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	114	22222	45	22222	32	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	115	22222	49	8.0999999999999996	38	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	116	22222	54	8.1999999999999993	60	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	117	22222	45	6.7999999999999998	36	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	118	22222	49	7.4000000000000004	46	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	119	22222	37	5.5999999999999996	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	120	22222	49	8	48	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	121	22222	41	22222	22	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	122	22222	54	9.3000000000000007	66	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	123	22222	42	6.7999999999999998	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	124	22222	46	7.2000000000000002	38	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	125	22222	42	7.2999999999999998	50	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	127	22222	51	7.2000000000000002	52	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	128	22222	43	6.2999999999999998	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	129	22222	44	6.5999999999999996	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	130	22222	42	6.2000000000000002	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	131	22222	45	6.5	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	132	22222	44	6.5999999999999996	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	133	22222	48	22222	34	4	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	134	22222	53	22222	48	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	135	22222	46	22222	34	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	136	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	137	22222	43	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	138	22222	45	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	139	22222	46	22222	40	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	140	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	141	22222	41	6.0999999999999996	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	142	22222	44	22222	30	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	143	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	144	22222	41	22222	24	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	145	22222	40	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	146	22222	42	22222	26	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	147	22222	39	22222	20	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	148	22222	42	22222	28	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	149	22222	47	22222	36	3	f	би	0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	150	22222	42	6.7000000000000002	30	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	50	0	673	151	22222	51	8.1999999999999993	56	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	4	22222	39	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	5	22222	47	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	10	22222	40	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	14	22222	46	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	16	22222	48	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	20	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	22	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	24	22222	29	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	28	22222	47	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	33	22222	45	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	34	22222	42	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	35	22222	45	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	39	22222	47	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	44	22222	37	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	46	22222	44	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	47	22222	40	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	49	22222	40	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	50	22222	37	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	51	22222	41	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	52	22222	46	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	53	22222	47	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	54	22222	46	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	57	22222	30	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	59	22222	36	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	60	22222	49	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	63	22222	42	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	64	22222	48	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	67	22222	42	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	70	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	72	22222	33	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	75	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	77	22222	63	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	79	22222	49	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	80	22222	44	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	81	22222	35	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	84	22222	29	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	86	22222	50	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	87	22222	45	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	88	22222	44	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	90	22222	28	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	93	22222	50	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	95	22222	50	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	96	22222	42	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	97	22222	57	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	98	22222	47	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	100	22222	36	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	101	22222	64	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	103	22222	41	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	104	22222	41	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	105	22222	44	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	109	22222	45	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	111	22222	47	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	113	22222	44	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	114	22222	53	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	116	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	117	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	118	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	119	22222	40	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	120	22222	42	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	123	22222	41	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	124	22222	35	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	125	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	126	22222	36	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	129	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	131	22222	46	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	132	22222	44	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	134	22222	42	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	137	22222	48	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	138	22222	45	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	140	22222	45	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	141	22222	30	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	145	22222	42	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	149	22222	45	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	51	0	673	151	22222	47	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	1	22222	44	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	3	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	5	22222	47	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	7	22222	51	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	9	22222	41	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	12	22222	40	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	13	22222	41	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	15	22222	41	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	16	22222	40	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	17	22222	38	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	18	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	19	22222	35	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	22	22222	45	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	23	22222	36	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	24	22222	48	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	25	22222	36	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	26	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	28	22222	46	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	30	22222	40	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	31	22222	33	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	32	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	34	22222	44	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	35	22222	36	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	36	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	38	22222	45	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	40	22222	47	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	41	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	42	22222	45	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	43	22222	31	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	44	22222	61	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	45	22222	41	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	47	22222	33	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	50	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	51	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	52	22222	47	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	54	22222	45	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	58	22222	45	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	59	22222	47	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	62	22222	35	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	64	22222	44	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	65	22222	45	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	67	22222	44	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	69	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	70	22222	34	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	71	22222	39	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	72	22222	39	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	73	22222	54	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	74	22222	41	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	76	22222	31	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	77	22222	39	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	78	22222	56	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	80	22222	30	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	83	22222	52	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	84	22222	47	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	85	22222	38	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	88	22222	42	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	89	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	90	22222	45	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	93	22222	39	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	94	22222	43	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	95	22222	41	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	97	22222	42	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	98	22222	46	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	52	0	673	99	22222	46	22222	22222	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	53	0	673	3	22222	43	6.0999999999999996	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	53	0	673	4	22222	42	6.5	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	53	0	673	6	22222	40	5.2000000000000002	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	53	0	673	20	22222	27	3.7999999999999998	10	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	53	0	673	21	22222	43	6	34	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	53	0	673	23	22222	40	5.7999999999999998	22	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	53	0	673	24	22222	42	6	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	53	0	673	26	22222	39	5.9000000000000004	24	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	53	0	673	28	22222	38	6.2000000000000002	22	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	1	22222	105	26.899999999999999	490	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	2	22222	87	19.600000000000001	260	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	3	22222	76	15.5	172	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	4	22222	69	11.199999999999999	106	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	5	22222	61	9.3000000000000007	92	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	7	22222	35	4	18	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	8	22222	79	22222	172	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	31	22222	40	5.5	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	32	22222	46	22222	40	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	33	22222	44	6.5	36	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	34	22222	41	22222	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	35	22222	39	5.5999999999999996	28	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	36	22222	38	5.2999999999999998	26	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	37	22222	48	8	44	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	38	22222	36	5.4000000000000004	22	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	54	0	673	39	22222	35	5	20	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	1	22222	68	15.199999999999999	130	5	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	2	22222	73	16	148	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	3	22222	64	22222	98	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	4	22222	68	11.6	110	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	5	22222	91	15.699999999999999	267	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	6	22222	65	11.199999999999999	96	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	7	22222	67	11.5	106	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	8	22222	63	22222	84	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	9	22222	74	22222	116	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	10	22222	60	11	80	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	11	22222	60	9.1999999999999993	76	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	12	22222	47	6.7999999999999998	34	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	13	22222	46	7.5999999999999996	32	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	14	22222	47	7.7000000000000002	46	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	15	22222	46	7.0999999999999996	42	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	16	22222	47	22222	38	3	m		0	22222	2	\N	\N	\N	\N	\N
2000	000а	1	55	0	673	17	22222	45	6.5	34	3	m		0	22222	2	\N	\N	\N	\N	\N
2010	УАХФ	12	2	0	666	1	81	80	22222	105	5	m		270	5	26					345667
2010	УАХФ	12	2	0	666	2	92	90	22222	22222	2	m		3584	22222	26					
2010	УАХФ	12	2	0	666	3	63	66	22222	22222	2	f	ир	16	22222	26					
\.


--
-- Data for Name: bioanalis_craboid; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY bioanalis_craboid (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec, lkarapax, wkarapax, weight, moltingst, sex, eggs, leglost, illnesscode, observcode, comment1, comment2, comment3, comment4, label) FROM stdin;
2010	УАХФ	12	1	2	661	1	22222	167	22222	4	m		1024	22222	26					
\.


--
-- Data for Name: bioanalis_echinoidea; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY bioanalis_echinoidea (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec, bodydiametr, bodyheight, bodyweight, gonadweight, sex, gonadcolor, gonadindex, observcode, comment1, comment2, comment3, comment4) FROM stdin;
\.


--
-- Data for Name: bioanalis_golotur; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY bioanalis_golotur (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec, weight, kmmweight, observcode, comment1, comment2, comment3, comment4) FROM stdin;
2000	000а	1	16	0	10574	2	123	456	2	qqqqq	wwwww	eeeee	rrrrr
2000	000а	1	16	0	10574	1	12.4	11.800000000000001	2	11111 аааа	22222 бббб	33333 ввввв	44444 гггггггг
2010	0001	1	5	1	10576	1	123	124	2	ййййй	ццццц	уууууу	ккккккк
\.


--
-- Data for Name: bioanalis_krevet; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY bioanalis_krevet (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec, lkarapax, mlength, weight, moltingst, sex, eggs, gonad, sternal, illnesscode, observcode, comment1, comment2, comment3, comment4) FROM stdin;
2000	000а	1	56	0	10006	1	123	1233	123	3	f	би			22222	5				
2000	000а	1	56	0	10006	2	123	22222	22222	3	f	ир	с		15	5				
2010	УАХФ	12	2	0	684	1	41	22222	50	3	i			0	2	26				
2010	УАХФ	12	2	0	684	2	47	22222	22222	2	m			1	22222	26				
2010	УАХФ	12	2	0	684	3	38	22222	22222	2	m			1	22222	26				
\.


--
-- Data for Name: bioanalis_krill; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY bioanalis_krill (myear, vesselcode, numsurvey, numstn, speciescode, numspec, lkarapax, weight, sex, stagepetasma, condgenapert, condamp, spfform, stagetelicum, condspf, spermball, stageovary, maturstage, illnesscode, observcode, comment1, comment2, comment3, comment4) FROM stdin;
\.


--
-- Data for Name: bioanalis_molusk; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY bioanalis_molusk (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec, shellheight, shellwidth, weight, sex, age, observcode, comment1, comment2, comment3, comment4) FROM stdin;
2000	000а	1	56	0	10533	1	56	223	12	m	1	2	11111	22222	33333	444444
2010	УАХФ	12	2	0	10126	1	58	34	230	m	22222	26				
2010	УАХФ	12	2	0	10126	2	24	11	22222	m	22222	26				
2010	УАХФ	12	2	0	10126	3	56	23	124	m	5	26				
\.


--
-- Data for Name: bioanalis_pelecipoda; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY bioanalis_pelecipoda (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec, shellheight, shelllength, bodywght, gonadwght, musclewght, sex, age, gonadcolor, illnesscode, observcode, comment1, comment2, comment3, comment4) FROM stdin;
2000	000а	1	56	0	10084	1	12	34	22222	22222	22222	m	22222		22222	2				
\.


--
-- Data for Name: bioanalis_squid; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY bioanalis_squid (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec, mlength, weight, sex, stagemat, substagemat, mating, stomach, observcode, comment1, comment2, comment3, comment4) FROM stdin;
\.


--
-- Data for Name: catch; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY catch (myear, vesselcode, numsurvey, numstn, grup, speciescode, measure, catch, commcatch, samplewght, observcode, comment1, comment2, comment3, catchpromm, catchnonpromm, catchf, weightm, weightf, weightj) FROM stdin;
2010	0001	1	3	2	669	0	1	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	12	2	673	0	4	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	13	2	673	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	14	2	673	0	3	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	15	2	673	0	103	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	16	2	673	0	41	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	17	2	673	0	15	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	18	2	673	0	2	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	19	2	673	0	3	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	20	2	673	0	6	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	21	2	673	0	9	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	22	2	673	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	23	2	673	0	1	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	24	2	673	0	24	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	25	2	673	0	1	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	26	2	673	0	1	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	27	2	673	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	28	2	673	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	29	2	673	0	7	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	30	2	673	0	8	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	31	2	673	0	1	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	32	2	673	0	140	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	33	2	673	0	262	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	34	2	673	0	305	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	35	2	673	0	176	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	36	2	673	0	114	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	37	2	673	0	66	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	38	2	673	0	18	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	39	2	673	0	4	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	40	2	673	0	31	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	41	2	673	0	24	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	42	2	673	0	3	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	45	2	673	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	46	2	673	0	400	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	47	2	673	0	230	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	48	2	673	0	168	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	49	2	673	0	348	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	50	2	673	0	318	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	51	2	673	0	800	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	52	2	673	0	228	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	53	2	673	0	30	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	54	2	673	0	39	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	55	2	673	0	48	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	56	2	673	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	12	2	673	0	4	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	12	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	13	2	673	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	13	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	14	2	673	0	3	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	14	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	15	2	673	0	103	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	15	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	16	2	673	0	41	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	16	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	17	2	673	0	15	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	17	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	18	2	673	0	2	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	18	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	19	2	673	0	3	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	19	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	20	2	673	0	6	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	20	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2010	0001	1	4	9	10514	1	123	12	22222	2	1111	2222	33333	22222	22222	22222	0	0	0
2010	0001	1	4	9	10518	1	134	123	22222	2				22222	22222	22222	0	0	0
2010	0001	1	4	9	20213	1	12	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	21	2	673	0	9	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	21	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	22	2	673	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	22	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	23	2	673	0	1	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	23	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	24	2	673	0	24	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	24	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	25	2	673	0	1	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	25	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	26	2	673	0	1	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	26	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	27	2	673	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	27	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	28	2	673	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	28	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	29	2	673	0	7	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	29	2	671	0	1	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	30	2	673	0	8	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	30	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	31	2	673	0	1	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	31	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	32	2	673	0	140	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	32	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	33	2	673	0	262	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	33	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	34	2	673	0	305	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	34	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	35	2	673	0	176	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	35	2	671	0	2	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	36	2	673	0	114	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	36	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	37	2	673	0	66	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	37	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	38	2	673	0	18	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	38	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	39	2	673	0	4	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	39	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	40	2	673	0	31	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	40	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	41	2	673	0	24	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	41	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	42	2	673	0	3	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	42	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	45	2	673	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	45	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	46	2	673	0	400	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	46	2	671	0	3	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	47	2	673	0	230	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	47	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	48	2	673	0	168	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	48	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	49	2	673	0	348	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	49	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	50	2	673	0	318	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	50	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	51	2	673	0	800	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	51	2	671	0	1	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	52	2	673	0	228	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	52	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	53	2	673	0	30	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	53	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	54	2	673	0	39	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	54	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	55	2	673	0	48	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	55	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	56	2	673	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	2	56	2	671	0	0	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	16	8	10574	1	123	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	56	6	10533	1	123	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	56	5	10084	1	33	22222	22222	2				22222	22222	22222	0	0	0
2000	000а	1	56	1	10006	1	123	22222	22222	5				22222	22222	22222	0	0	0
2010	УАХФ	12	2	6	10126	1	675	22222	1356	26				22222	22222	22222	0	0	0
2010	УАХФ	12	2	2	666	0	0	22222	125	26				22222	22222	22222	0	0	0
2010	УАХФ	12	2	1	684	1	234	12	228	26				22222	22222	22222	0	0	0
2010	УАХФ	12	2	4	10262	1	456	22222	22222	26				22222	22222	22222	0	0	0
2010	УАХФ	12	3	3	661	0	0	22222	22222	23				22222	22222	22222	0	0	0
\.


--
-- Data for Name: gear_spr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY gear_spr (gearcode, mtype, name, kf, vertraskr, gorizraskr, sizecell, selectresh, numbin, kf1, kf2, h, nagivka, soblov, lvaer, kolkr1, kolkr2, numkr) FROM stdin;
10	1	тралируемое ОЛ	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
11	1	трал донный	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
12	1	трал разноглубинный (крупнотон. судно)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
13	1	трал разноглубинный (среднетон.судно)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
14	1	трал близнецовый донный	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
15	1	трал близнецовый придонный	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
16	1	трал близнецовый разноглубинный	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
17	1	трал близнецовый	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
18	1	бимтрал	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
19	1	трал научно-исследовательский	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
20	2	невод	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
21	2	невод закидной равнокрылый,притоняемый к берегу	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
22	2	невод закидной неравнокрылый,притоняемый к берегу	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
23	2	невод безмотенный (волокуша)	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
24	2	невод распорный,притоняемый к судну,плоту	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
25	2	невод закидной	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
26	2	невод ставной	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
27	1	трал пелагический	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
28	1	трал креветочный	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
29	2	невод речной вобельный	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
30	3	сеть	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
31	3	сеть ставная	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
32	3	сеть плавная	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
33	3	сеть обметная	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
34	3	сеть ставная сиговая	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
35	3	сеть крупночастиковая	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
36	3	сеть ставная крупноячейная	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
37	3	сеть ставная мелкоячейная	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
39	4	ловушки прямоугольные	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
40	4	ловушка	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
41	4	ловушка стационарная	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
42	4	ловушка,периодически передвигаемая	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
43	4	ловушка дрейфующая	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
44	4	ловушка-ризцы	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
45	4	ловушка-ризцы снетковые	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
46	4	ловушка-мережа	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
47	4	вентерь	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
48	4	ловушка угревая	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
49	4	ловушка коническая	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
50	5	поводковое ОЛ	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
51	5	наживное стационарное ОЛ-ярус	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
52	5	наживное стационарное ОЛ-перемет	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
53	5	наживное стационарное ОЛ-удочка	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
54	5	ненаживное стационарное ОЛ	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
55	5	наживное буксируемое ОЛ-тролл	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
56	5	наживное буксируемое ОЛ-спиннинг	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
57	5	дрейфующее ОЛ	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
58	5	крючья	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
59	3	сеть донная	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
60	6	рыбонасос	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
61	2	донный ярус	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
70	7	кошелькующееся ОЛ	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
71	7	кошельковый невод одноботный	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
72	7	кошельковый невод двуботный	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
73	7	аламан	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
74	7	лампара	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
75	3	кольцевая сеть	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
80	8	накидка	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
81	8	накидка ручная	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
82	8	накидка механическая	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
83	8	накидка выстреливаемая	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
90	9	мутник	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
91	9	мутник (снюрревод) буксируемый	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
92	9	мутник (снюрревод) небуксируемый	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
100	10	драга	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
101	10	драга ручная	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
102	10	драга судовая	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
110	11	сачок	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
111	11	сачок с фиксированным устьем	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
112	11	сачок с закрывающимся устьем	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
120	12	поддон	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
121	12	поддон ручной	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
122	12	поддон механический	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
123	12	поддон пневматический	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
130	13	электрофизическое ОЛ	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
140	14	рыбоучетное заграждение	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
150	15	рыбоход	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
160	16	неизвестное ОЛ	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
170	17	заколы	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
171	17	заколы крупноячейные	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
210	2	снюрревод	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
221	5	береговой	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
222	5	прибрежный	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
223	5	судовой, пелагический	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
224	4	рюжи	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
300	2	невод распорный, ячея 40мм	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
301	3	сеть плавная 60-70 мм	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
302	2	невод стержевой	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
303	3	сеть плавная 30,36,40 мм	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
304	3	сети ячея 22-70 мм	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
305	3	сети 36-40 мм	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
306	3	аханы	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
307	3	курляндка	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
308	3	сеть ставная 40 мм	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
309	3	сеть ставная 45 мм	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
310	3	сеть ставная 50 мм	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
311	3	сеть ставная 18 мм	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
312	3	сеть мелкочастиковая	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
313	2	невод-двойник	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
314	2	невод механизированный	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: grunt_spr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY grunt_spr (bottomcode, name, mtype, size_mm) FROM stdin;
1	Глыбы	Валуны	1000-500
2	Валуны крупные	Валуны	500-250
3	Валуны средние	Валуны	250-100
4	Валуны мелкие	Галечник	100-50
5	Галечник крупный	Галечник	50-25
6	Галечник средний	Галечник	25-10
7	Галечник мелкий	Гравий	10-5
8	Гравий крупный	Гравий	5-2,5
9	Гравий средний	Гравий	2,5-1,0
10	Гравий мелкий	Песок	1,0-0,5
11	Песок крупный	Песок	0,50-0,25
12	Песок средний	Песок	0,25-0,10
13	Песок мелкий	Илистый песок	0,10-0,05
14	Алеврит крупный	Илистый песок	0,05-0,01
15	Ил мелкоалевритовый	Ил	0,01-0,007
16	Ил алевроитоглинистый	Ил	<0,007
17	Ил глинистый	Ил	<0,007
0	Неизвестно		
\.


--
-- Data for Name: illness_spr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY illness_spr (illnesscode, mtype, name, comment) FROM stdin;
0	0	 Нет болезней	\t\n
1	1	Argeia pugettensis	Isopoda,В жаберной полости у креветок сем. Crangonidae\n
2	1	Bopyriodes hippolytes	Isopoda, вызывает вздутия по бокам карапакса, обитает на жабрах креветок\n
3	1	Briarosaccus callosus	Rhizocephala, на крабоидах, на бр. стороне карапакса, продолговатый мешок от оранжевого до красного цвета\n
4	1	Crangonobdella fabricii	Hirudinea, отмечена на креветках и крабах\n
5	1	Crangonobdella maculosa	Hirudinea, отмечена на крабах\n
6	1	Crangonobdella murmanica	Hirudinea, отмечена на крабах\n
7	1	Hematodinium perezi	"Dinoflagellata, вызывает ""белую горечь"" у крабов, покровы становятся молочного цвета"\n
8	1	Hemiarthrus abdominalis	Isopoda, у креветок, на нижней стороне абдомена, между 1 и 2 парой плеопод\n
9	1	Holophryxus alaskensis	Isopoda, На спинной стороне креветок головой назад\n
10	1	Ischyrocerus anguipes	Симбиотические бокоплавы, возможно питаются икрой хозяина. Отмечены на ротовых частях, брюшной стороне абдомена, жабрах\n
11	1	Ischyrocerus commensalis	Симбиотические бокоплавы, возможно питаются икрой хозяина. Отмечены на ротовых частях, брюшной стороне абдомена, жабрах\n
12	1	Johanssonia arctica	Hirudinea, отмечена на креветках и крабах\n
13	1	Microphallus turgidus	Trematoda, Digenea Креветки Palaemonetes spp. являются промежуточным хозяином, обитает в мускульной ткани\n
14	1	Mycetomorpha vancouverensis	Rhizocephala, на нижней стороне абдомена, имеет вид многочисленных продолговатых долек\n
15	1	Notostomum cyclostomum	Hirudinea, отмечена на крабах\n
16	1	Phryxus abdominalis	Isopoda, обитает на креветках, на брюшной стороне абдомена\n
17	1	Sylon hippolytes	Rhizocephala, на нижней стороне абдомена, имеет вид продолговатого округлого мешка розовато-молочного цвета\n
18	1	Thalassomyces capillosus	Protista, Прикрепляется стебельком,  проникающим  сквозь  покровы,  в дорзальной  передней части  головогруди (перед  эпигастральным  шипом). Стебелек разветвляется на множество длинных тонких выростов (гономеров), которые  продуцируют  споры.  Хозяева  э
19	1	Thelohaenia  sp.	Microsporidia, внутриклеточный паразит, поражает мышечную ткань креветок. Особи имеют молочно-белый цвет, мясо становится горьким.\n
20	1	Trachelosaccus hymenodorae	Rhizocephala, на нижней стороне абдомена, имеет вид продолговатого округлого мешка, отмечен только для Hymenodora glacialis в Северной Атлантике\n
21	1	Trichomaris invadens	Fungi, вызывает локальное почернение карапакса краба, имеет вид пленки со спороносящими телами на карапаксе \n
22	1	Бактериальный некроз	Почернение участка карапакса, вызывается хитинолитическими бактериями нескольких систематических групп\n
23	2	Грибковый некроз гребешков	Дистрофия и некроз мягких тканей. Возбудитель не найден.\n
22222	0		
\.


--
-- Data for Name: jurnalcatchstrat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY jurnalcatchstrat (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, square, catchsht, catchgram) FROM stdin;
2010	0001	1	5	1	10576	1	2	3
2010	УАХФ	12	1	1	661	22222	22222	22222
2010	УАХФ	12	1	2	661	22222	22222	22222
\.


--
-- Data for Name: jurnalstrat; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY jurnalstrat (myear, vesselcode, numsurvey, numstn, numstrat, depthbeg, depthend, tbottom, bottomcode, proc, bottomcode1, proc1) FROM stdin;
2010	0001	1	5	1	0	5	1	0	22222	0	22222
2010	УАХФ	12	1	1	2.5	7.5	22222	0	22222	0	22222
2010	УАХФ	12	1	2	7.5	10	22222	0	22222	0	22222
\.


--
-- Data for Name: observ_spr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY observ_spr (observcode, name, placework, qualification) FROM stdin;
1	Алексеев Дмитрий Олегович	ВНИРО	
2	Бизиков Вячеслав Александрович	ВНИРО	
3	Бисерова Наталья Александровна	ВНИРО	
4	Бочарова Екатерина Сергеевна	ВНИРО	
5	Гончар Андрей Леонидович	ВНИРО	
6	Горянина Светлана Васильевна	ВНИРО	
7	Карпинский Михаил Георгиевич	ВНИРО	
8	Лищенко Федор Витальевич	ВНИРО	
9	Моисеев Сергей Иванович	ВНИРО	
11	Сологуб Денис Олегович	ВНИРО	
14	Шевченко Илья Николаевич	ВНИРО	
15	Штрик Вадим Александрович	ВНИРО	
16	Штрик Мария Владимировна	ВНИРО	
17	Соколов Василий Игоревич	ВНИРО	
18	Загорский Иван Александрович	ВНИРО	
19	Васильев Роман Михайлович	ВНИРО	
20	Борисов Ростислав Русланович	ВНИРО	
21	Паршин-Чудин Андрей Витальевич	ВНИРО	
22	Переладов Михаил Владимирович	ВНИРО	
23	Буяновский Алексей Ильич	ВНИРО	
24	Вагин Александр Владимирович	ВНИРО	
25	Полонский Вячеслав Евгеньевич	ВНИРО	
26	Огурцов Александр Юрьевич	ВНИРО	
27	Тальберг Наталья Борисовна	ВНИРО	
28	Сидоров Лев Константинович	ВНИРО	
29	Сабурин Михаил Юрьевич	ВНИРО	
30	Вилкова Ольга Юрьевна	ВНИРО	
31	Войдаков Евгений Владимирович	ВНИРО	
32	Рой Иван Владимирович	ВНИРО	
\.


--
-- Data for Name: promer; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY promer (myear, vesselcode, numsurvey, numstn, speciescode, sex, sizeclass, numb) FROM stdin;
2010	УАХФ	12	2	10262	0	1	1
2010	УАХФ	12	2	10262	0	2	1
2010	УАХФ	12	2	10262	0	3	1
2010	УАХФ	12	2	10262	0	5	2
2010	УАХФ	12	2	10262	0	6	1
2010	УАХФ	12	2	10262	0	7	2
2010	УАХФ	12	2	10262	0	9	21
2010	УАХФ	12	2	10262	0	10	23
2010	УАХФ	12	2	10262	0	13	21
2010	УАХФ	12	2	10262	0	14	23
2010	УАХФ	12	2	10262	0	19	21
\.


--
-- Data for Name: species_spr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY species_spr (speciescode, namerus, namelat, grup, m_order, family, minlength, maxlength, minweight, maxweight) FROM stdin;
10144	Осьминог мексиканский четырехглазый	Octopus maya Voss, Solis, 1966	squid	Octopoda		0	500	0	0
10145	Осьминог четырехпятенный	Octopus selene Voss, 1971	squid	Octopoda		0	500	0	0
10146	Осьминог обыкновенный	Octopus vulgaris Cuvier, 1797	squid	Octopoda		0	500	0	0
10147	Осьминог хлысторукий	Octopus variabilis (Sasaki, 1929)	squid	Octopoda		0	500	0	0
10148	Осьминог четырехрогий	Pteroctopus tetracirrhus (Delle Chiaje, 1830)	squid	Octopoda		0	500	0	0
10149	Осьминог - батиполипус салеброзус	Bathypolypus salebrosus (Sasaki, 1920)	squid	Octopoda		0	100	0	0
10150	Осьминог - батиполипус Вальдивия	Bathypolypus valdiviae (Chun et Thile 1915)	squid	Octopoda		0	100	0	0
10151	Осьминог - батиполипус спонсалис	Bathypolypus sponsalis (Fischer et Fischer, 1892)	squid	Octopoda		0	100	0	0
10152	Осьминог -батиполипус арктический	Bathypolypus arcticus (Prosch, 1849)	squid	Octopoda		0	100	0	0
10153	Осьминог - старушка	Cistopus indicus Gray, 1840	squid	Octopoda		0	200	0	0
10154	Осьминог малый обыкновенный	Eledone cirrosa (Lamarck, 1798)	squid	Octopoda		0	100	0	0
10155	Осьминог Масси	Eledone massyae Voss, 1964	squid	Octopoda		0	100	0	0
10156	Осьминог Шарко	Pareledone charcoti (Joubin, 1905)	squid	Octopoda		0	200	0	0
10157	Осьминог гранеледоне бородавчатый	Graneledone verrucosa (Verrill, 1881)	squid	Octopoda		0	200	0	0
10158	Осьминог гранеледоне Челленджера	Graneledone challengeri (Berry, 1916)	squid	Octopoda		0	200	0	0
10159	Осьминог антарктический бородавчатый	Graneledone antarcticus Voss, 1976	squid	Octopoda		0	300	0	0
10160	Осьминог - цветная капуста	Graneledone macrotyla Voss, 1976	squid	Octopoda		0	300	0	0
10161	Осьминог антарктический бугорчатый	Pareledone polymorpha (Robson, 1930)	squid	Octopoda		0	200	0	0
10162	Осьминог антарктический малобородавчатый	Pareledone turqueti (Joubin, 1905)	squid	Octopoda		0	200	0	0
10163	Осьминог эледонелла	Eledonella Pygmaea Verrill, 1884	squid	Octopoda		0	200	0	0
10164	Осьминог глазчатый	Euaxoctopus pillsburyae Voss, 1975	squid	Octopoda		0	200	0	0
10165	Осьминог бентоктопус сибирский	Benthoctopus sibiricus Loeyning, 1930	squid	Octopoda		0	100	0	0
10166	Осьминог бентоктопус японский	Benthoctopus abruptus (Sasaki, 1920)	squid	Octopoda		0	100	0	0
10167	Осьминог бентоктопус фускус	Benthoctopus fuscus Taki, 1964	squid	Octopoda		0	100	0	0
10168	Осьминог бентоктопус атлантический	Benthoctopus ergasticus (Fischer and Fischer, 1892)	squid	Octopoda		0	100	0	0
10169	Осьминог бентоктопус рыбацкий	Benthoctopus piscatorum (Verill, 1879)	squid	Octopoda		0	100	0	0
10170	Осьминог бентоктопус глубоководный	Benthoctopus profundorum Robson, 1932	squid	Octopoda		0	100	0	0
704	Артротамнус курильский	Arthrothamnus kurilensis	algae			0	0	0	0
705	Агарум решетчатый	Agarum cribrosum	algae			0	0	0	0
706	Алария окаймленная	Alaria marginata	algae			0	0	0	0
707	Алария охотская	Alaria ochotensis	algae			0	0	0	0
708	Алария полая	Alaria fistulosa	algae			0	0	0	0
709	Алария узкая	Alaria angustata	algae			0	0	0	0
710	Алария съедобная	Alaria esculenta	algae			0	0	0	0
711	Артротамнус нерасщепленный	Arthrothamnus bifidus	algae			0	0	0	0
712	Артротамнус расщепленный	Arthrothamnus bifidus	algae			0	0	0	0
713	Аскофиллум узловатый	Ascophyllum nodosum	algae			0	0	0	0
714	Костария ребристая	Costaria costata	algae			0	0	0	0
715	Ламинария Бонгарда	Laminaria bongardiana	algae			0	0	0	0
716	Ламинария Гурьяновой	Laminaria gurjanovae	algae			0	0	0	0
717	Ламинария длинная	Laminaria longipes	algae			0	0	0	0
718	Ламинария зубчатая	Laminaria dentigera	algae			0	0	0	0
719	Ламинария йезоензис	Laminaria yezoensis	algae			0	0	0	0
720	Ламинария копытная	Laminaria solidungula	algae			0	0	0	0
721	Ламинария лентовидная	Laminaria taeniata	algae			0	0	0	0
722	Ламинария многоскладчатая	Laminaria multiplicata	algae			0	0	0	0
723	Ламинария наклоненная	Laminaria inclinatorhiza	algae			0	0	0	0
724	Ламинария пальчаторассеченная	Laminaria digitata	algae			0	0	0	0
10171	Осьминог бентоктопус хоккайдский	Benthoctopus hokkaidensis (Berry, 1921)	squid	Octopoda		0	100	0	0
10172	Осьминог бентоктопус мускулистый	Benthoctopus violescens Taki, 1964	squid	Octopoda		0	100	0	0
10173	Осьминог бентоктопус эурека	Benthoctopus eureka (Robson, 1929)	squid	Octopoda		0	100	0	0
10174	Осьминог бентоктопус фолклендский	Benthoctopus januarii (Hoyle, 1885)	squid	Octopoda		0	100	0	0
10175	Осьминог бентоктопус Берри	Benthoctopus berryi Robson, 1924	squid	Octopoda		0	100	0	0
10176	Осьминог бентоктопус магелланский	Benthoctopus magellanicus Robson 1930	squid	Octopoda		0	100	0	0
10177	Осьминог бентоктопус левис	Benthoctopus levis (Hoyle, 1885)	squid	Octopoda		0	100	0	0
10178	Осьминог бентоктопус кергеленский	Benthoctopus thielei Robson, 1932	squid	Octopoda		0	100	0	0
10179	Осьминог бентоктопус орегонский	Benthoctopus oregonae Toll, 1981	squid	Octopoda		0	100	0	0
10180	Осьминог - оса синекольчатый	Hapalochlaena lunulata (Quoy et Gaimard, 1832)	squid	Octopoda		0	100	0	0
10181	Осьминог - оса синеполосчатый	Hapalochlaena maculosa (Hoyle, 1883)	squid	Octopoda		0	100	0	0
10182	Осьминог стекловидный	Vitreledonella richardi Joubin, 1918	squid	Octopoda		0	300	0	0
10183	Осьминог планктонный сетчатый	Ocythoe tuberculata Rafinesque, 1814	squid	Octopoda		0	500	0	0
10184	Осьминог  -тремоктопус крылорукий	Tremoctopus violaceus delle Chiaje, 1830	squid	Octopoda		0	200	0	0
10185	Осьминог - аргонавт обыкновенный	Argonauta argo Linne, 1758	squid	Octopoda		0	200	0	0
10186	Осьминог - аргонавт узловатый	Argonauta nodosa Solander, 1786	squid	Octopoda		0	200	0	0
10187	Осьминог - аргонавт хианс	Argonauta hians Solander, 1786	squid	Octopoda		0	200	0	0
10188	Осьминог - аргонавт мелкобугорчатый	Argonauta boettgeri Maltzan, 1881	squid	Octopoda		0	300	0	0
10189	Осьминог - аллопосус моллис	Alloposus millis Verrill, 1880	squid	Octopoda		0	600	0	0
10190	Осьминог болитена	Bolitaena microcotyla Steenstrup in Hoyle, 1886	squid	Octopoda		0	100	0	0
10191	Осьминог япетелла	Japetella diaphana Hoyle, 1885	squid	Octopoda		0	200	0	0
10192	Осьминог амфитретус	Amphitretus pelagicus Hoyle, 1885	squid	Octopoda		0	200	0	0
736	Фукус исчезающий	Fucus evanescens	algae			0	0	0	0
737	Фукус пузырчатый	Fucus vesiculosus	algae			0	0	0	0
738	Фукус спиральный	Fucus spiralis	algae			0	0	0	0
739	Циматера двухскладчатая	Cymathaere ribroza	algae			0	0	0	0
740	Циматера трехскладчатая	Cymathaere triplicata	algae			0	0	0	0
741	Циматера японская	Cymathaere japonica	algae			0	0	0	0
742	Цистозейра бородатая	Cystoseira barbata	algae			0	0	0	0
743	Цистозейра  косматая	Cystoseira crinita	algae			0	0	0	0
744	Цистозейра толстоногая	Cystoseira crassipes	algae			0	0	0	0
745	Челльманиелла кольцевая	Kjellamiella gyrata	algae			0	0	0	0
746	Челльманиелла толстолистая	Kjellamiella crassifollia	algae			0	0	0	0
747	Анфельция складчатая	Ahnfeltia plicata	algae			0	0	0	0
748	Анфельция тобучинская	Ahnfeltia tobuchiensis	algae			0	0	0	0
749	Грацилярия бородавочная	Gracilaria verrucosa	algae			0	0	0	0
750	Одонталия охотская	Odonthalia ochotensis	algae			0	0	0	0
751	Порфира	Porhyra sp.	algae			0	0	0	0
752	Тихокарпус косматый	Tichocarpus crinitus	algae			0	0	0	0
753	Филлофора ребристая	Phyllophora nervosa	algae			0	0	0	0
754	Фурцеллярия равновершинная	Furcellaria lumbricalis	algae			0	0	0	0
755	Хондрус	Chondrus sp.	algae			0	0	0	0
756	Кладофора	Cladophora sp.	algae			0	0	0	0
757	Зостера азиатская	Zostera asiatica	algae			0	0	0	0
758	Зостера морская	Zostera marina	algae			0	0	0	0
759	Филлоспадикс	Phyllospadix iwatensis	algae			0	0	0	0
769	Одонталия	Odonthalia sp.	algae			0	0	0	0
770	Птилота	Ptilota sp.	algae			0	0	0	0
771	Родимения	Rhodymenia sp.	algae			0	0	0	0
772	Родомела	Rhodomela sp.	algae			0	0	0	0
773	Кодиум	Codium sp.	algae			0	0	0	0
774	Монострома	Monostroma sp.	algae			0	0	0	0
775	Ульва	Ulva sp.	algae			0	0	0	0
10193	Осьминог идиоктопус	Idioctopus gracilipes Taki, 1962	squid	Octopoda		0	200	0	0
10194	Осьминог цирротаума	Cirrothauma murrayi Chun, 1911	squid	Octopoda		0	600	0	0
10195	Осьминог стауротеутис	Stauroteuthis syrtensis Verril, 1879	squid	Octopoda		0	600	0	0
10196	Осьминог цирротеутис Мюллера	Cirroteuthis muelleri Eschricht, 1838	squid	Octopoda		0	600	0	0
10197	Осьминог гримпотеутис тихоокеанский	Grimpoteuthis pacifica (Hoyle, 1885)	squid	Octopoda		0	600	0	0
10198	Осьминог гримпотеутис большекрылый	Grimpoteuthis megaptera (Verrill, 1885)	squid	Octopoda		0	500	0	0
10199	Осьминог гримпотеутис зонтичный	Grimpoteuthis umbellata (Fischer, 1883)	squid	Octopoda		0	500	0	0
10200	Осьминог гримпотеутис ледяной	Grimpoteuthis glacialis (Robson, 1930)	squid	Octopoda		0	500	0	0
10201	Осьминог гримпотеутис Моусона	Grimpoteuthis mowsoni (Berry, 1917)	squid	Octopoda		0	500	0	0
10202	Осьминог гримпотеутис тихоокеанский	Grimpoteuthis albatrossi (Sasali, 1920)	squid	Octopoda		0	500	0	0
10203	Осьминог гримпотеутис атлантический	Grimpoteuthis grimaldii (Joubin, 1903)	squid	Octopoda		0	500	0	0
10204	Осьминог гримпотеутис плена	Grimpoteuthis plena (Verrill, 1885)	squid	Octopoda		0	500	0	0
10060	Анадара Броутона	Anadara broughtoni	pelecipoda	Mytilida	Arcidae	0	100	0	0
10061	Мидия Грея	Crenomytilus grayanus	pelecipoda	Mytilida	Mytilidae	0	100	0	0
10062	Мидия средиземноморская	Mytilus galloprovincialis	pelecipoda	Mytilida	Mytilidae	0	100	0	0
10063	Мидия съедобная	Mytilus edulis   Linnaeus, 1758	pelecipoda	Mytilida	Mytilidae	0	100	0	0
10064	Мидия тихоокеанская	Mytilus trossulus	pelecipoda	Mytilida	Mytilidae	0	100	0	0
10065	Модиолус обыкновенный	Modiolus modiolus	pelecipoda	Mytilida	Mytilidae	0	100	0	0
10066	Устрица тихоокеанская	Crassostrea gigas	pelecipoda	Mytilida	Ostreidae	0	150	0	0
10067	Устрица обыкновенная	Ostrea edulis	pelecipoda	Mytilida	Ostreidae	0	150	0	0
10068	Устрица пластинчатая	Ostrea lamellosa	pelecipoda	Mytilida	Ostreidae	0	150	0	0
10069	Скафарка Броутона	Scapharca broughtoni	pelecipoda			0	100	0	0
20004	Угольная рыба	Anoplopoma fimbria Pallas, 1814\n	pisces			0	0	0	0
20141	Горбуша	Oncorhynchus gorbuscha (Walbaum, 1792)\n	pisces			0	0	0	0
20152	Минога тихоокеанская	Lampetra japonica Martens\n	pisces			0	0	0	0
20176	Сайра	Cololabis saira (Brevoort, 1856)\n	pisces			0	0	0	0
20211	Скат Мацубары	Bathyraja matsubarai (Ishlyama, 1952)\n	pisces			0	0	0	0
20212	Скат алеутский	Bathyraja aleutica (Gilbert, 1896)\n	pisces			0	0	0	0
20213	Скат звездчатый	Raja radiata (Donovan, 1808)\n	pisces			0	0	0	0
20217	Окунь морской алеутский	Sebastes aleutianus (Jordan et Evermann, 1898)\n	pisces			0	0	0	0
20218	Клювач тихоокеанский	Sebastes alutus (Gilbert, 1890)\n	pisces			0	0	0	0
20221	Окунь морской северный	Sebastes borealis Barsukov, 1970\n	pisces			0	0	0	0
20222	Шипощек аляскинский	Sebastolobus alascanus (Bean,1890)\n	pisces			0	0	0	0
20223	Шипощек длинноперый	Sebastolobus mackrochir (Gunther, 1877)\n	pisces			0	0	0	0
20229	Язык морской	Pegusa lascaris (Risso, 1810)\n	pisces			0	0	0	0
20236	Терпуг восьмилинейный	Hexagrammos octogrammus (Pallas, 1814)\n	pisces			0	0	0	0
20237	Терпуг зайцеголовый	Hexagrammos lagocephalus (Pallas, 1810)\n	pisces			0	0	0	0
20238	Терпуг северный одноперый	Pleurogrammus monopterygius (Pallas, 1810)\n	pisces			0	0	0	0
20239	Терпуг южный одноперый	Pleurogrammus azonus Jordan et Metz, 1913\n	pisces			0	0	0	0
20240	Терпуг Стеллера	Hexagrammos stelleri Tilesius, 1810\n	pisces			0	0	0	0
20243	Минтай	Theragra chalcogramma (Pallas, 1814)\n	pisces			0	0	0	0
20244	Навага	Eleginus nawaga (Koelreuter, 1770)\n	pisces			0	0	0	0
20245	Навага тихоокеанская	Eleginus gracilis (Tilesius, 1810)\n	pisces			0	0	0	0
20249	Сайка	Boreogadus saida (Lepechin, 1774)\n	pisces			0	0	0	0
20254	Треска тихоокеанская	Gadus macrocephalus Tilesius, 1810\n	pisces			0	0	0	0
20591	Керчак дальневосточный	Myoxocephalus stelleri Tilesius, 1811\n	pisces			0	0	0	0
20595	Ликод Солдатова	Lycodes soldatovi Taranetz et Andriashev, 1935\n	pisces			0	0	0	0
20597	Долгохвост вооруженный	Coryphaenoides armatus (Hector, 1875)\n	pisces			0	0	0	0
20605	Окунь морской голубой	Sebastes glaucus Hilgendorf, 1880\n	pisces			0	0	0	0
20618	Палтус тихоокеанский белокорый	Hippoglossus hippoglossus stenolepis Schmidt\n	pisces			0	0	0	0
20624	Сельдь тихоокеанская	Clupea pallasii Valenciennes, 1847\n	pisces			0	0	0	0
20628	Ставрида японская	Trachurus japonicus (Temminck et Schlegel, 1844)\n	pisces			0	0	0	0
20919	Камбала дальневосточная длинная	Glyptocephalus stelleri (Schmidt, 1904)\n	pisces			0	0	0	0
20920	Камбала колючая Надежного	Acanthopsetta nadeshnyi Schmidt, 1904\n	pisces			0	0	0	0
21111	Скат	Bathyraja sp.\n	pisces			0	0	0	0
21112	Терпуг	Hexagrammos sp.\n	pisces			0	0	0	0
21113	Ликод	Lycodes sp.\n	pisces			0	0	0	0
10128	Сиг волховский	Coregonus lavaretus baeri Kessler, 1864	pisces			0	1000	0	0
10592	Астериас амурский	Asterias amurensis Lutken	asteroidea			0	0	0	0
10593	Астериас аргонавта	Asterias argonauta Djakonov	asteroidea			0	0	0	0
10594	Астериас микродискус	Asterias microdiscus Djakonov	asteroidea			0	0	0	0
10595	Астериас ратбуни	Asterias rathbuni (Verrill)	asteroidea			0	0	0	0
10596	астериас роллестони	Asterias rollestoni Bell	asteroidea			0	0	0	0
10597	Астериас красный	Asterias rubens Linnaeus	asteroidea			0	0	0	0
10598	Астериас цветоизменчивый	Asterias versicolor Sladen	asteroidea			0	0	0	0
10599	Астроклес актинодетус	Astrocles actinodetus Fisher	asteroidea			0	0	0	0
10600	Астропектен иррегулярис	Astropecten irregularis (Linck)	asteroidea			0	0	0	0
10601	Батибиастер вексиллифер	Bathybiaster vexillifer (W. Thomson)	asteroidea			0	0	0	0
10602	Бентопектен ропалофорус	Benthopecten rhopalophorus Djakonov	asteroidea			0	0	0	0
10603	Бризингелла охотская	Brisingella ochotensis Djakonov	asteroidea			0	0	0	0
10604	Церамастер арктический	Ceramаster arcticus (Verrill)	asteroidea			0	0	0	0
10605	Церамастер гранулярис	Ceramаster granularis Retzius	asteroidea			0	0	0	0
10606	Церамастер японский	Ceramаster japonicus (Sladen)	asteroidea			0	0	0	0
10607	Церамастер патагонский	Ceramаster patagonicus (Sladen)	asteroidea			0	0	0	0
10608	Церамастер стеллатус	Ceramаster stellatus Djakonov	asteroidea			0	0	0	0
10609	Кроссастер бореалис	Crossaster borealis Fisher	asteroidea			0	0	0	0
10610	Кроссастер диамесус	Crossaster diamesus (Djakonov)	asteroidea			0	0	0	0
10611	Кроссастер японский	Crossaster japonicus (Fisher)	asteroidea			0	0	0	0
10136	Осьминог гигантский	Enteroctopus dofleini (Wulker, 1910)	squid	Octopoda		0	500	0	0
10137	Осьминог песчаный	Octopus conispadiceus (Sasaki, 1917)	squid	Octopoda		0	500	0	0
10138	Осьминог сетчатый	Octopus aegina Gray, 1849	squid	Octopoda		0	500	0	0
10139	Осьминог карибский рифовый	Octopus briareus Robson, 1929	squid	Octopoda		0	500	0	0
10140	Осьминог калифорнийский четырехглазый	Octopus bimaculatus Verill, 1883	squid	Octopoda		0	500	0	0
10141	Осьминог синий четырехглазый	Octopus cyanea Gray, 1849	squid	Octopoda		0	500	0	0
10114	Исландская циприна	Arctica islandica	pelecipoda	Cardiida	Arcticoidea	0	60	0	0
10129	Наутилус стеномфалус	Nautilus stenomphalus Sowerby, 1849	squid	Nautilida		0	300	0	0
10130	Наутилус скробикулятус	Nautilus scrobiculatus Solander, 1786	squid	Nautilida		0	300	0	0
10131	Наутилус макромфалус	Nautilus macromphalus Sowerby, 1849	squid	Nautilida		0	300	0	0
10132	Наутилус репертус	Nautilus repertus Iredale, 1944	squid	Nautilida		0	300	0	0
10133	Наутилус попмилиус	Nautilus pompilius Linneus, 1758	squid	Nautilida		0	300	0	0
10134	Спирула обыкновенная	Spirula spirula (Linneus, 1758)	squid	Spirulida		0	100	0	0
10135	Вампир адский	Vampyroteuthis infernalis Chun, 1903	squid	Vampyroteuthida		0	200	0	0
10142	Осьминог большерукий	Octopus macropus Risso, 1826	squid	Octopoda		0	500	0	0
10143	Осьминог светлоголовый четырехглазый	Octopus membranaceus Quoy et Gaimard, 1832	squid	Octopoda		0	500	0	0
10121	Береговички (Литторины)	Littorina	molusk			0	40	0	0
10122	Букцинумы	Buccinum	molusk			0	150	0	0
10123	Рапана	Rapana thamasiana thamasiana  Crosse, 1861	molusk	Bucciniformes	Thaididae	0	200	0	0
10124	Волютопсиусы	Volutopsis	molusk			0	150	0	0
10125	Луссиволютопсиусы	Lussivolutopsius	molusk			0	100	0	0
10126	Нептунеи	Neptunea	molusk			0	150	0	0
10127	Пирулофузусы	Pyrulofusus	molusk			0	100	0	0
10612	Кроссастер паппозус	Crossaster papposus (Linne)	asteroidea			0	0	0	0
10613	Кроссастер скуаматус	Crossaster squamatus (Doderlein)	asteroidea			0	0	0	0
10614	Ктенодискус криспатус	Ctenodiscus crispatus Retzius	asteroidea			0	0	0	0
10615	Диплоптерастер мултипес	Diplopteraster multipes (Sars)	asteroidea			0	0	0	0
10616	Дипсокастер аноплус	Dipsacaster anoplus Fisher	asteroidea			0	0	0	0
10617	Дистоластериас элеганс	Distolasterias elegans Djakonov	asteroidea			0	0	0	0
10618	Дистоластериас нипон	Distolasterias nipon (Doderlein)	asteroidea			0	0	0	0
10619	Эремирастер тенебрариус	Eremiraster tenebrarius (Fisher)	asteroidea			0	0	0	0
10620	Эвастериас дерюгини	Evasterias derjugini (Djakonov)	asteroidea			0	0	0	0
10621	Эвастериас эхиносома	Evasterias echinosoma Fisher	asteroidea			0	0	0	0
10622	Эвастериас ретифера	Evasterias retifera Djakonov	asteroidea			0	0	0	0
10623	Эвастериас трощели	Evasterias troscheli (Stimpson)	asteroidea			0	0	0	0
10624	Гефирастер свифти	Gephyreaster swifti (Fisher)	asteroidea			0	0	0	0
10625	Хенриция арктическая	Henricia arctica Verrill	asteroidea			0	0	0	0
10626	Хенриция аспера	Henricia aspera Fisher	asteroidea			0	0	0	0
10627	Хенриция берингиана	Henricia beringiana Djakonov	asteroidea			0	0	0	0
10628	Хенриция дерюгини	Henricia derjugini Djakonov	asteroidea			0	0	0	0
10629	Хенриция дискрита	Henricia dyscrita Fisher	asteroidea			0	0	0	0
10630	Хенриция элеганс	Henricia elegans Djakonov	asteroidea			0	0	0	0
10631	Хенриция эшрихти	Henricia eschrichtii (Muller et Troschel)	asteroidea			0	0	0	0
10632	Хенриция книповичи	Henricia knipowitschi Djakonov	asteroidea			0	0	0	0
10633	Хенриция левиускула	Henricia leviuscula (Stimpson)	asteroidea			0	0	0	0
10634	Хенриция лонгиспина	Henricia longispina Fisher	asteroidea			0	0	0	0
10635	Хенриция охотская	Henricia ochotensis Djakonov	asteroidea			0	0	0	0
10636	Хенриция восточная	Henricia orientalis Djakonov	asteroidea			0	0	0	0
10637	Хенриция сангуинолента	Henricia sanguinolenta O.F. Muller	asteroidea			0	0	0	0
20022	Макрурус малоглазый	Albatrossia pectoralis (Gilbert, 1892)\n	pisces			0	0	0	0
10205	Осьминог гримпотеутис тропический	Grimpoteuthis hippocrepium (Houle, 1904)	squid	Octopoda		0	500	0	0
10206	Осьминог опистотеутис Агассица	Opisthoteuthis agassizi Verril, 1883	squid	Octopoda		0	500	0	0
10207	Осьминог опистотеутис калифонийский	Opisthoteuthis californiana Berry, 1949	squid	Octopoda		0	500	0	0
10208	Осьминог опистотеутис плоский	Opisthoteuthis depressa Ijima et Ikeda, 1895	squid	Octopoda		0	500	0	0
10209	Осьминог опистотеутис японский	Opisthoteuthis japonica Taki, 1962	squid	Octopoda		0	500	0	0
10210	Осьминог опистотеутис медузовидный	Opisthoteuthis medusoides Thiele, 1915	squid	Octopoda		0	500	0	0
10211	Осьминог опистотеутис широкий	Opisthoteuthis extensa Thiele, 1915	squid	Octopoda		0	500	0	0
10212	Осьминог опистотеутис австралийский	Opisthoteuthis pluto Berry, 1918	squid	Octopoda		0	500	0	0
10213	Осьминог опистотеутис серый	Opisthoteuthis persephone Berry, 1918	squid	Octopoda		0	500	0	0
10638	Хенриция скабриор	Henricia scabrior (Michailovskij)	asteroidea			0	0	0	0
10639	Хенриция скорикови	Henricia skorikovi Djakonov	asteroidea			0	0	0	0
10640	Хенриция солида	Henricia solida Djakonov	asteroidea			0	0	0	0
10641	Хенриция спекулифера	Henricia spiculifera (Clark)	asteroidea			0	0	0	0
10642	Хенриция тумида	Henricia tumida Verrill	asteroidea			0	0	0	0
10643	Хиппастериа колосса	Hippasteria colossa Djakonov	asteroidea			0	0	0	0
10644	Хиппастериа дерюгини	Hippasteria derjugini Djakonov	asteroidea			0	0	0	0
10645	Хиппастериа курильская	Hippasteria kurilensis Fisher	asteroidea			0	0	0	0
10646	Хиппастериа лейопелта	Hippasteria leiopelta Fisher	asteroidea			0	0	0	0
10647	Хиппастериа маммифера	Hippasteria mammifera Djakonov	asteroidea			0	0	0	0
10648	Хиппастериа педицелларис	Hippasteria pedicellaris Djakonov	asteroidea			0	0	0	0
10649	Хиппастериа фригиана	Hippasteria phrygiana Parelius	asteroidea			0	0	0	0
10650	Хиппастериа спиноза	Hippasteria spinosa Verrill	asteroidea			0	0	0	0
10651	Хименастер глаукус	Hymenaster glaucus Sladen	asteroidea			0	0	0	0
10652	Хименастер пеллуцидус	Hymenaster pellucidus W. Thomson	asteroidea			0	0	0	0
10653	Хименастер периссонотус	Hymenaster perissonotus Fisher	asteroidea			0	0	0	0
10654	Икастериас панопла	Icasterias panopla (Stuxberg)	asteroidea			0	0	0	0
10655	Коретрастер хиспидус	Korethraster hispidus W. Thomson	asteroidea			0	0	0	0
10656	Лептастериас аляскенсис азиатика	Leptasterias alaskensis asiatica Fisher	asteroidea			0	0	0	0
10657	Лептастериас арктический	Leptasterias arctica Murdoch	asteroidea			0	0	0	0
10658	Лептастериас камчатский	Leptasterias camtschatica (Brandt)	asteroidea			0	0	0	0
10659	Лептастериас коеи шантарика	Leptasterias coei shantarica Djakonov	asteroidea			0	0	0	0
10660	Лептастериас дербеки	Leptasterias derbeki Djakonov	asteroidea			0	0	0	0
10661	Лептастериас диспар	Leptasterias dispar Verrill	asteroidea			0	0	0	0
10662	Лептастериас фишери	Leptasterias fisheri Djakonov	asteroidea			0	0	0	0
10663	Лептастериас гранулята	Leptasterias granulata Djakonov	asteroidea			0	0	0	0
10664	Лептастериас гренландский	Leptasterias groenlandica Steenstrup	asteroidea			0	0	0	0
10665	Лептастериас гекзактис оцциденталис	Leptasterias hexactis occidentalis Djakonov	asteroidea			0	0	0	0
10666	Лептастериас хирсута	Leptasterias hirsuta Djakonov	asteroidea			0	0	0	0
10667	Лептастериас хилодес	Leptasterias hylodes Fisher	asteroidea			0	0	0	0
10668	Лептастериас инсоленс	Leptasterias insolens Djakonov	asteroidea			0	0	0	0
10669	Лептастериас лептодома	Leptasterias leptodoma Fisher	asteroidea			0	0	0	0
10670	Лептастериас мюллери	Leptasterias mulleri Sars	asteroidea			0	0	0	0
10671	Лептастериас охотский	Leptasterias ochotensis (Brandt)	asteroidea			0	0	0	0
10672	Лептастериас восточный	Leptasterias orientalis Djakonov	asteroidea			0	0	0	0
10673	Лептастериас полярис ацервата	Leptasterias polaris acervata (Stimpson)	asteroidea			0	0	0	0
10674	Лептастериас полярис ушакови	Leptasterias polaris ushakovi Djakonov	asteroidea			0	0	0	0
10675	Лептастериас полиморфа	Leptasterias polymorpha Djakonov	asteroidea			0	0	0	0
10676	Лептастериас шмидти	Leptasterias schmidti Djakonov	asteroidea			0	0	0	0
10677	Лептастериас сибирский	Leptasterias sibirica Djakonov	asteroidea			0	0	0	0
10678	Лептастериас симилиспинус	Leptasterias similispinus (Clark)	asteroidea			0	0	0	0
10679	Лептастериас скуамата	Leptasterias squamulata Djakonov	asteroidea			0	0	0	0
10680	Лептастериас субарктика	Leptasterias subarctica Djakonov	asteroidea			0	0	0	0
10681	Лептастериас виноградови	Leptasterias vinogradovi Djakonov	asteroidea			0	0	0	0
10682	Лептастериас гиперборея	Leptesterias hyperborea (Danielssen et Koren)	asteroidea			0	0	0	0
10683	лептикастер аномалюс	Leptychaster anomalus Fisher	asteroidea			0	0	0	0
10684	Лептикастер арктический	Leptychaster arcticus Sars	asteroidea			0	0	0	0
10685	Лептикастер инермис	Leptychaster inermis (Ludwig)	asteroidea			0	0	0	0
10687	Летастериас фуска	Lethasterias fusca Djaconov	asteroidea			0	0	0	0
10688	Летастериас нанимиенсис челифера	Lethasterias nanimiensis chelifera (Verrill)	asteroidea			0	0	0	0
10689	Лопастер фурцифер	Lophaster furcifer Duben et Koren	asteroidea			0	0	0	0
10690	Лопастер фурциллигер	Lophaster furcilliger Fisher	asteroidea			0	0	0	0
10691	Луидия куинария	Luidia quinaria v. Martens	asteroidea			0	0	0	0
10692	Луидиастер доусони	Luidiaster dawsoni (Verrill)	asteroidea			0	0	0	0
10693	Луидиастер туберкулятус	Luidiaster tuberculatus Djakonov	asteroidea			0	0	0	0
10694	Лизастросома антостика	Lysastrosoma anthosticta Fisher	asteroidea			0	0	0	0
10695	Мартастериас полярный	Marthasterias glacialis (Linnaeus)	asteroidea			0	0	0	0
10696	Миксодерма дерюгини	Myxoderma derjugini Djakonov	asteroidea			0	0	0	0
10697	Неархастер педицеллярис	Nearchaster pedicellaris (Fisher)	asteroidea			0	0	0	0
10698	Неархастер вариабилис геминус	Nearchaster variabilis (Fisher) ssp. geminus Djakonov	asteroidea			0	0	0	0
10699	Патирия пектинифера	Patiria pectinifera (Muller et Troschel)	asteroidea			0	0	0	0
10700	Педицеллястер эксимиус	Pedicellaster eximius Djakonov	asteroidea			0	0	0	0
10701	Педицеллястер индистинктус	Pedicellaster indistinctus Djakonov	asteroidea			0	0	0	0
10702	Педицеллястер магистер охотский	Pedicellaster magister ochotensis Djakonov	asteroidea			0	0	0	0
10703	Педицеллястер восточный	Pedicellaster orientalis Fisher	asteroidea			0	0	0	0
10704	Педицеллястер типикус	Pedicellaster typicus Sars	asteroidea			0	0	0	0
10705	Периболастер бисериалис	Peribolaster biserialis Fisher	asteroidea			0	0	0	0
10706	Понтастер тенуспинус	Pontaster tenuspinus Duben et Koren	asteroidea			0	0	0	0
10707	Пораниоморфа биденс	Poraniomorpha bidens Mortensen	asteroidea			0	0	0	0
10708	Пораниоморфа хиспида	Poraniomorpha hispida Sars	asteroidea			0	0	0	0
10709	Пораниоморфа тумида	Poraniomorpha tumida (Stuxberg)	asteroidea			0	0	0	0
10710	Пораниопсис инфлята	Poraniopsis inflata (Fisher)	asteroidea			0	0	0	0
10711	Псевдархастер орнатус	Pseudarchaster ornatus Djakonov	asteroidea			0	0	0	0
10712	Псевдархастер парели	Pseudarchaster parelii Duben et Koren	asteroidea			0	0	0	0
10713	Псиластер андромеда	Psilaster andromeda Muller et Troschel	asteroidea			0	0	0	0
10714	Псиластер пектинатус	Psilaster pectinatus (Fisher)	asteroidea			0	0	0	0
10715	Птерастер марсиппус	Pteraster marsippus Fisher	asteroidea			0	0	0	0
10716	Птерастер милитарис	Pteraster militaris O.F. Muller	asteroidea			0	0	0	0
10717	Птерастер обскурус	Pteraster obscurus Perrier	asteroidea			0	0	0	0
10718	Птерастер октастер	Pteraster octaster Verrill	asteroidea			0	0	0	0
10719	Птерастер пулвиллус	Pteraster pulvillus Sars	asteroidea			0	0	0	0
10720	Птерастер темнохитон	Pteraster temnochiton Fisher	asteroidea			0	0	0	0
10721	Птерастер тесселатус	Pteraster tesselatus Ives	asteroidea			0	0	0	0
10722	Солястер доусони	Solaster dawsoni Verrill	asteroidea			0	0	0	0
10723	Солястер эндека	Solaster endeca Linnaeus	asteroidea			0	0	0	0
10724	Солястер полярный	Solaster glacialis Danielssen et Koren	asteroidea			0	0	0	0
10536	Волюта кергеленская	Provocator pulcher	molusk			0	80	0	0
10725	Солястер промежуточный	Solaster intermedius Hayashi	asteroidea			0	0	0	0
10726	Солястер тихоокеанский	Solaster pacificus Djakonov	asteroidea			0	0	0	0
10727	Солястер паппосус	Solaster papposus Linnaeus	asteroidea			0	0	0	0
10728	Солястер паксиллатус	Solaster paxillatus Sladen	asteroidea			0	0	0	0
10729	Солястер скуаматус	Solaster sguamatus Doderlein	asteroidea			0	0	0	0
10730	Солястер стимпсони	Solaster stimpsoni Verrill	asteroidea			0	0	0	0
10731	Солястер сиртенсис	Solaster syrtensis Verrill	asteroidea			0	0	0	0
10732	Стефанастериас албула	Stephanasterias albula Stimpson	asteroidea			0	0	0	0
10733	Триссакантус биспиносус	Thrissacanthias bispinosus Djakonov	asteroidea			0	0	0	0
-6	 Неопределенный вид F	 Undefined F	\N			0	0	0	0
-5	 Неопределенный вид E	 Undefined E	\N			0	0	0	0
-4	 Неопределенный вид D	 Undefined D	\N			0	0	0	0
-3	 Неопределенный вид C	 Undefined C	\N			0	0	0	0
-2	 Неопределенный вид B	 Undefined B	\N			0	0	0	0
-1	 Неопределенный вид A	 Undefined A	\N			0	0	0	0
10413	Кальмар - фолидотеутис Адама	Pholidoteuthis adami Voss, 1956	squid	Teuthida		0	1000	0	0
10452	Кальмар - орегониотеутис	Oregoniateuthis sppringeri Voss, 1956	squid	Teuthida		0	99	0	0
10529	Необукцинум антарктический	Neobuccinum eatoni	molusk			0	100	0	0
10530	Трофон белогубый	Trophon albolabratus	molusk			0	70	0	0
10531	Блюдечко южноантильское	Nacella concinna	molusk			0	70	0	0
10532	Блюдечко плоское	Nacella edgari	molusk			0	70	0	0
10533	Блюдечко кергеленское	Nacella kerguelenensis	molusk			0	100	0	0
10534	Многозубка удивительная	Perissodonta mirabilis	molusk			0	80	0	0
10535	Волюта Чаркот	Harpovoluta charcoti	molusk			0	80	0	0
10514	Криль подледный	Euphausia crystallorophias	krill	Euphausiida		0	40	0	0
10515	Криль-фригида	Euphausia frigida	krill	Euphausiida		0	40	0	0
10516	Криль антарктический	Euphausia superba	krill	Euphausiida		0	70	0	0
10517	Криль трехзубый	Euphausia triacantha	krill	Euphausiida		0	50	0	0
10518	Криль Валентина	Euphausia vallentini	krill	Euphausiida		0	40	0	0
10519	Черноглазка антарктическая	Thysanoessa macrura	krill	Euphausiida		0	40	0	0
10491	Кальмар - галитеутис тихоокеанский	Galiteuthis pacifica (Robson, 1948)	squid	Teuthida		0	700	0	0
10492	Кальмар - мегалокранхия абиссальная	Megalocranchia abyssicola (Goodrich, 1896)	squid	Teuthida		0	600	0	0
10493	Кальмар - мегалокранхия океанская	Megalocranchia oceanica (Voss, 1960)	squid	Teuthida		0	600	0	0
10494	Кальмар - белонелла белоне	Belonella belone (Chun, 1906)	squid	Teuthida		0	600	0	0
10495	Кальмар - белонелла бореальная	Belonella borealis Nesis, 1972	squid	Teuthida		0	600	0	0
10496	Кальмар - лигурелла подофтальма	Ligurella podophtalma Issel, 1908	squid	Teuthida		0	500	0	0
10497	Кальмар - лигурелла пардус	Ligurella pardus (Berry, 1916)	squid	Teuthida		0	500	0	0
10498	Кальмар - теутовения мегалопс	Teuthowenia megalops (Prosch, 1849)	squid	Teuthida		0	400	0	0
10503	Кальмар - личия циклюра	Leachia cyclura LeSueur, 1821	squid	Teuthida		0	300	0	0
10753	Стегофиура нодоза	Stegophiura nodosa Lutken	echinoidea			0	0	0	0
10552	Аллотионе лонгикауда	Allothyone longicauda (Oestergren)	golotur			0	700	0	0
10553	Хиридота бесцветная	Chiridota discolor Eschscholtz	golotur			0	700	0	0
10554	Хиридота лаевис	Chiridota laevis Fabricius	golotur			0	700	0	0
10556	Кукумария североатлантическая	Cucumaria frondosa Gunnerus	golotur	Dendrochirota		0	700	0	0
10557	Кукумария ледяная	Cucumaria glacialis Ljungman	golotur	Dendrochirota		0	200	0	0
10558	Кукумария японская	Cucumaria japonica Semper	golotur	Dendrochirota		0	700	0	0
10559	Кукумария миниата	Cucumaria miniata (Brandt)	golotur	Dendrochirota		0	700	0	0
10560	Кукумари обунка	Cucumaria obunca Lampert	golotur	Dendrochirota		0	700	0	0
10561	Кукумария сахалинская	Cucumaria sachalinica Djakonov	golotur	Dendrochirota		0	700	0	0
10562	Кукумария вега	Cucumaria vegae Theel	golotur	Dendrochirota		0	200	0	0
10563	Эльпидия полярная	Elpidia glacialis Theel	golotur			0	700	0	0
10564	Эупертакта фраудатрикс	Eupentacta fraudatrix (Djakonov et Baranova)	golotur			0	700	0	0
10565	Эупиргус пацификус	Eupyrgus pacificus Oestergren	golotur			0	700	0	0
10566	Эупиргус скабер	Eupyrgus scaber Lutken	golotur			0	700	0	0
10567	Лабидоплакс буски	Labidoplax buski M. Intosh	golotur			0	700	0	0
10568	Лабидоплакс вариабилис	Labidoplax variabilis Theel	golotur			0	700	0	0
10569	Молпадия бореалис	Molpadia borealis M. Sars	golotur			0	700	0	0
10591	Афалестерия японская	Aphelasterias japonica Bell	asteroidea			0	0	0	0
10589	Пелиометра проликса	Peliometra prolixa Sladen	crinoidea			0	400	0	0
10590	Хелиометра полярная	Heliometra glacialis Learch	crinoidea			0	400	0	0
10686	Лептикастер пропингуус	Leptychaster propinquus Fisher	asteroidea			0	0	0	0
20023	Макрурус пепельный	Coryphaenoides cinereus (Gilbert, 1892)\n	pisces			0	0	0	0
20024	Макрурус черный	Coryphaenoides acrolepis (Bean, 1884)\n	pisces			0	0	0	0
20027	Зубатка дальневосточная	Anarhichas orientalis Pallas, 1814\n	pisces			0	0	0	0
20031	Камбала восточная двухлинейная	Lepidopsetta bilineata (Ayres, 1855)\n	pisces			0	0	0	0
20035	Камбала желтополосая	Pseudopleuronectes herzensteini (Jordan et Snyder, 1901)\n	pisces			0	0	0	0
20036	Камбала звездчатая	Platichthys stellatus (Pallas, 1787)\n	pisces			0	0	0	0
20040	Камбала узкозубая палтусовидная	Hippoglossoides elassodon Jordan et Gilbert, 1880\n	pisces			0	0	0	0
20047	Палтус азиатский стрелозубый	Atheresthes evermanni Jordan et Starks, 1904\n	pisces			0	0	0	0
20048	Палтус черный	Reinhardtius hippoglossoides (Walbaum, 1792)\n	pisces			0	0	0	0
20113	Кета	Oncorhynchus keta (Walbaum, 1792)\n	pisces			0	0	0	0
20114	Кижуч	Oncorhunchus kisutch (Walbaum, 1792)\n	pisces			0	0	0	0
20115	Кумжа	Salmo trutta Linnaeus, 1758\n	pisces			0	0	0	0
20116	Кунджа	Salvelinus leucomaenis (Pallas, 1814)\n	pisces			0	0	0	0
20123	Нерка	Oncorhynchus nerka (Walbaum, 1792)\n	pisces			0	0	0	0
20139	Чавыча	Oncorhynchus tschawytscha (Walbaum, 1792)\n	pisces			0	0	0	0
10734	Троходискус алмус	Trophodiscus almus Fisher	asteroidea			0	0	0	0
10735	Троходискус убер	Trophodiscus uber Djakonov	asteroidea			0	0	0	0
10736	Тиластер виллей	Tylaster willei Danielssen et Koren	asteroidea			0	0	0	0
10737	Урастериас линки	Urasterias lincki Muller et Troschel	asteroidea			0	0	0	0
20559	Акула тихоокеанская полярная	Somniosus pacificus Bigelow et Schroeder, 1944\n	pisces			0	0	0	0
20560	Акула тихоокеанская сельдевая	Lamna ditropis Hubbs et Follett, 1947\n	pisces			0	0	0	0
20565	Бычок двурогий	Enophrys diceraus (Pallas, 1787)\n	pisces			0	0	0	0
20566	Бычок красный	Alcichthys elongatus (Steindachner, 1881)\n	pisces			0	0	0	0
20567	Бычок-бабочка	Hemilepidotus papilio (Bean,1880)\n	pisces			0	0	0	0
20569	Окунь морской восточный	Sebastes taczanowskii Steindachner, 1880\n	pisces			0	0	0	0
20576	Камбала дальневосточная малоротая	Microstomus achne (Jordan et Starks, 1904)\n	pisces			0	0	0	0
20580	Камбала сахалинская	Limanda sakhalinensis Hubbs, 1915\n	pisces			0	0	0	0
20585	Камбала япономорская палтусовидная	Hippoglossoides dubius Schmidt, 1904\n	pisces			0	0	0	0
20588	Керчак бородавчатый	Myoxocephalus verrucosus (Bean, 1881)\n	pisces			0	0	0	0
659	Краб Верилла	Paralomis verrilli	craboid	Decapoda	Lithodidae	0	200	0	0
660	Краб многошипый	Paralomis multispina	craboid	Decapoda	Lithodidae	0	200	0	0
666	Краб, волосатый пятиугольный	Telmessus cheiragonus	crab	Decapoda	Atelecyclidae	0	200	0	0
667	Краб, волосатый четырехугольный	Erimacrus isenbeckii	crab	Decapoda	Atelecyclidae	0	200	0	0
668	Краб мохнаторукий	Eriocheir japonicus	crab	Decapoda	Grapsidae	0	200	0	0
669	Краб каменный	Eriphia verrucosa Forskal, 1775	crab	Decapoda	Eriphiidae MacLeay, 1838	0	200	0	0
670	Краб эстуарный	Carcinus aestuarii Nardo, 1847	crab	Decapoda	Portunidae Dana, 1852	0	200	0	0
671	Краб-стригун, бэрди	Chionoecetes bairdi	crab	Decapoda	Majidae	0	200	0	0
672	Краб-стригун, красный	Chionoecetes japonicus	crab	Decapoda	Majidae	0	200	0	0
673	Краб-стригун, опилио	Chionoecetes opilio	crab	Decapoda	Majidae	0	200	0	0
10754	Трепанг	Apostychopus japonicus	golotur			0	0	0	0
10755	Кукумария охотская	Cucumaria ochotensis	golotur			0	0	0	0
10756	Кукумария фрондоза	Cucumaria frondosa	golotur			0	0	0	0
697	Креветка северная (атлантический подвид)	Pandalus borealis	krevet	Decapoda	Pandalidae	0	200	0	0
698	Креветка северная (тихоокеанский подвид)	Pandalus borealis eous	krevet	Decapoda	Pandalidae	0	200	0	0
699	Креветка углохвостая	Pandalus goniurus	krevet	Decapoda	Pandalidae	0	150	0	0
20589	Керчак многоиглый	Myoxocephalus polyacanthocephalus (Pallas,1814)\n	pisces			0	0	0	0
20590	Керчак снежный	Myoxocephalus brandtii (Steindachner, 1867)\n	pisces			0	0	0	0
661	Краб камчатский	Paralithodes camtschaticus	craboid	Decapoda	Lithodidae	0	400	0	0
662	Краб синий	Paralithodes platypus	craboid	Decapoda	Lithodidae	0	400	0	0
663	Краб колючий	Paralithodes brevipes	craboid	Decapoda	Lithodidae	0	300	0	0
664	Краб коуэзи	Lithodes couesi	craboid	Decapoda	Lithodidae	0	300	0	0
665	Краб равношипый	Lithodes aeguispinus	craboid	Decapoda	Lithodidae	0	300	0	0
10002	Краб муррайи	Lithodes murrayi	craboid	Decapoda	Lithodidae	0	300	0	0
10003	Краб марионский	Paralomis aculeata	craboid	Decapoda	Lithodidae	0	300	0	0
674	Краб-стригун, таннери	Chionoecetes tanneri	crab	Decapoda	Majidae	0	200	0	0
675	Краб-стригун, угловатый	Chionoecetes angulatus	crab	Decapoda	Majidae	0	200	0	0
10001	Краб травяной	Carcinus maenas	crab	Decapoda	Portunidae	0	201	0	0
10537	Еж морской зеленый	Strongylocentrotus droebachiensis (O.F. Muller)	echinoidea	Echinoida		0	150	0	0
10538	Еж морской промежуточный (серый)	Strongylocentrotus intermedius (A. Agassiz)	echinoidea	Echinoida		0	150	0	0
10539	Еж морской невооруженный (черный)	Strongylocentrotus nudus (A. Agassiz)	echinoidea	Echinoida		0	150	0	0
10540	Еж морской палевый	Strongylocentrotus pallidus (Sars)	echinoidea	Echinoida		0	150	0	0
10541	Еж морской многоиглый	Strongylocentrotus polyacanthus A. Agassiz et Clark	echinoidea	Echinoida		0	150	0	0
10542	Еж морской обыкновенный плоский	Echinarachnius parma (Lamarck)	echinoidea	Clypeasteroida		0	150	0	0
10543	Еж морской скафениус плоский	Scaphechinus mirabilis Agassiz	echinoidea	Clypeasteroida		0	150	0	0
10544	Еж морской скафениус серый	Scaphechinus griseus (Mortensen)	echinoidea	Clypeasteroida		0	150	0	0
10545	Еж морской скафениус Брыкова	Scaphechinus brykovi Budin	echinoidea	Clypeasteroida		0	150	0	0
10546	Еж морской съедобный	Echinus esculentus Linnaeua	echinoidea			0	150	0	0
10547	Бризастер фрагилис	Brisaster fragilis (Duber et Koren)	echinoidea			0	150	0	0
10548	Еж морской пурпурный	Spatangus purpureus O.F. Muller	echinoidea			0	150	0	0
10549	Еж морской сердцевидный	Echinocardium cordatum (Pennant)	echinoidea			0	150	0	0
10550	Пурталезия джефферси	Pourtalesia jeffeysi W. Thomson	echinoidea			0	150	0	0
10551	Эхиноциамус пусиллус	Echinocyamus pusillus O.F. Muller	echinoidea			0	150	0	0
10738	Амфиура бореалис	Amphiura borealis G.Sars	echinoidea			0	0	0	0
10739	Амфиура сундевалли	Amphiura sundevalli Muller et Troschel	echinoidea			0	0	0	0
10740	Астероникс ловени	Asteronyx loveni Muller et Troschel	echinoidea			0	0	0	0
10741	Горгоноцефалус арктикус	Gorgonocephalus arcticus Leach	echinoidea			0	0	0	0
10742	Горгоноцефалус эукнемис	Gorgonocephalus eucnemis Muller et Troschel	echinoidea			0	0	0	0
10743	Офиоканта бидентата	Ophiocantha bidentata Retzius	echinoidea			0	0	0	0
10744	Офиоктен серицеум	Ophiocten sericeum Forbes	echinoidea			0	0	0	0
10745	Офиофолис акулеата	Ophiopholis aculeata Linnaeus	echinoidea			0	0	0	0
10746	Офиоплевра бореалис	Ophiopleura borealis Dan. et Koren	echinoidea			0	0	0	0
10747	Офиопус арктикус	Ophiopus arcticus Ljungman	echinoidea			0	0	0	0
10748	Офиосколекс полярный	Ophioscolex glacialis Muller et Troschel	echinoidea			0	0	0	0
10749	Офиура аффинис	Ophiura affinis Lutken	echinoidea			0	0	0	0
10750	Офиура альбида	Ophiura albida Forbes	echinoidea			0	0	0	0
10751	Офиура робуста	Ophiura robusta Ayres	echinoidea			0	0	0	0
10752	Офиура сарси	Ophiura sarsi Lutken	echinoidea			0	0	0	0
10555	Кукумария кальцигера	Cucumaria calcigera Stimpson	golotur	Dendrochirota		0	200	0	0
10587	Трохостома арктическая	Trochostoma arcticum	golotur			0	700	0	0
10570	Мириотрохус минутус	Myriotrochus minutus Oestergren	golotur			0	700	0	0
10571	Мириотрохус митсуруки	Myriotrochus mitsukuri Ohshima	golotur			0	700	0	0
10572	Мириотрохус ринки	Myriotrochus rinkii Steenstrup	golotur			0	200	0	0
10573	Паракаудина рансонети	Paracaudina ransonetii (Marenzeller)	golotur			0	200	0	0
10574	Голотурия	Phyllophorus pellucidus Flemming	golotur			0	700	0	0
10575	Псолус фабриции	Psolus fabricii Duben et Koren	golotur			0	700	0	0
10576	Голотурия таинственная чешуйчатая	Psolus phantapus Strussenfelt	golotur			0	700	0	0
10577	Псолус регалис	Psolus regalis Verrill	golotur			0	700	0	0
10578	Сколиодотелла линдберги	Scoliodotella lindbergi (Djakonov)	golotur			0	700	0	0
10579	Трепанг дальневосточный	Stichopus japonicus Selenka	golotur	Aspidochirotida		0	700	0	0
10580	Стихопус тремулус	Stichopus tremulus Gunnerus	golotur	Aspidochirotida		0	200	0	0
10581	Синалактес нозаваи	Synallactes nozawai Mitsukuri	golotur			0	700	0	0
10582	Тионидиум обыкновенный	Thyonidium commune Forbes	golotur			0	700	0	0
10583	Тионидиум прозрачный	Thyonidium pellucidum Fleming	golotur			0	700	0	0
10584	Троходерма элеганс	Trochoderma elegans Theel	golotur			0	200	0	0
10585	Трохотстома оолитикум	Trochostoma ooliticum Pourtales	golotur			0	700	0	0
10586	Трохостома восточная	Trochostoma orientale Saveljeva	golotur			0	700	0	0
10588	Трохостома томсони	Trochostoma thomsoni Danielssen et Koren	golotur			0	700	0	0
676	Креветка алеутская	Pandalopsis aleutica	krevet	Decapoda	Pandalidae	0	150	0	0
677	Креветка виноградная	Pandalopsis coccinata	krevet	Decapoda	Pandalidae	0	150	0	0
678	Креветка охотоморская	Pandalopsis ochotensis	krevet	Decapoda	Pandalidae	0	150	0	0
679	Креветка пластинчатая	Pandalopsis lamelligera	krevet	Decapoda	Pandalidae	0	150	0	0
680	Креветка, полосатая равнолапая	Pandalopsis dispar	krevet	Decapoda	Pandalidae	0	150	0	0
681	Креветка, японская равнолапая	Pandalopsis japonica	krevet	Decapoda	Pandalidae	0	150	0	0
682	Креветка гребенчатая	Pandalus hypsinotus	krevet	Decapoda	Pandalidae	0	150	0	0
684	Креветка травяная	Pandalus latirostris	krevet	Decapoda	Pandalidae	0	150	0	0
686	Креветка гренландская	Lebbeus groenlandicus	krevet	Decapoda	Hyppolitidae	0	150	0	0
687	Креветка короткоклювая	Eualus macilentus	krevet	Decapoda	Hyppolitidae	0	150	0	0
688	Креветка, черноморская каменная	Palaemon elegans	krevet	Decapoda	Palemonidae Samouelle, 1819	0	80	0	0
690	Шримс бородавчатый	Rhynocrangon alata	krevet	Decapoda	Crangonidae	0	100	0	0
692	Шримс-медвежонок, северный	Sclerocrangon boreas	krevet	Decapoda	Crangonidae	0	100	0	0
694	Шримс козырьковый	Argis spp.	krevet	Decapoda	Crangonidae	0	100	0	0
695	Шримс песчаный	Crangon dalli	krevet	Decapoda	Crangonidae	0	100	0	0
696	Шримс промежуточный	Mesocrangon intermedia	krevet	Decapoda	Crangonidae	0	100	0	0
10004	Креветка равнолапая митсукури	Pandalopsis mitsukurii	krevet	Decapoda	Pandalidae	0	150	0	0
10005	Креветка равнолапая пунктатус	Pandalopsis punctatus	krevet	Decapoda	Pandalidae	0	150	0	0
10006	Креветка равнолапая шипастая	Pandalopsis multidentatus	krevet	Decapoda	Pandalidae	0	150	0	0
10007	Пандалус меридионалис	Pandalus meridionalis	krevet	Decapoda	Pandalidae	0	150	0	0
10008	Пандалус монтагуи триденс	Pandalus montagui tridens	krevet	Decapoda	Pandalidae	0	150	0	0
10009	Пандалус джордани	Pandalus jordani	krevet	Decapoda	Pandalidae	0	150	0	0
10010	Шримс Дерюгина	Sclerocrangon derjugini	krevet	Decapoda	Crangonidae	0	150	0	0
10011	Шримс-медвежонок, шипастый	Sclerocrangon salebrosa	krevet	Decapoda	Crangonidae	0	150	0	0
10012	Склерокрангон шарпи	Sclerocrangon sharpi	krevet	Decapoda	Crangonidae	0	100	0	0
10013	Склерокрангон спинирострис	Sclerocrangon spinirostris	krevet	Decapoda	Crangonidae	0	100	0	0
10014	Скеоркрангон вариабилис	Sclerocrangon variabilis	krevet	Decapoda	Crangonidae	0	100	0	0
10015	Склерокрангон коммунис	Sclerocrangon communis	krevet	Decapoda	Crangonidae	0	100	0	0
10016	Склерокрангон интермедиа	Sclerocrangon intermedia	krevet	Decapoda	Crangonidae	0	100	0	0
10017	Склерокрангон лаевис	Sclerocrangon laevis	krevet	Decapoda	Crangonidae	0	100	0	0
10018	Склерокрангон алата	Sclerocrangon alata	krevet	Decapoda	Crangonidae	0	100	0	0
10019	Нектокрангон робуста	Nectocrangon robusta	krevet	Decapoda	Crangonidae	0	100	0	0
10020	Нектокрангон красса	Nectocrangon crassa	krevet	Decapoda	Crangonidae	0	100	0	0
10021	Нектокрангон овифер	Nectocrangon ovifer	krevet	Decapoda	Crangonidae	0	100	0	0
10022	Нектокрангон дентата	Nectocrangon dentata	krevet	Decapoda	Crangonidae	0	100	0	0
10023	Нектокрангон лар кобякови	Nectocrangon lar kobjakovi	krevet	Decapoda	Crangonidae	0	100	0	0
10024	Нектокрангон лар лар	Nectocrangon lar lar	krevet	Decapoda	Crangonidae	0	100	0	0
10025	Леббеус брандти	Lebbeus brandti	krevet	Decapoda	Hyppolitidae	0	100	0	0
10026	Леббеус шренкии	Lebbeus schrenckii	krevet	Decapoda	Hyppolitidae	0	100	0	0
10027	Леббеус спинирострис	Lebbeus spinirostris	krevet	Decapoda	Hyppolitidae	0	100	0	0
10028	Леббеус лонгипес	Lebbeus longipes	krevet	Decapoda	Hyppolitidae	0	100	0	0
10029	Леббеус фасциата	Lebbeus fasciata	krevet	Decapoda	Hyppolitidae	0	100	0	0
10030	Леббеус ушакови	Lebbeus uschakovi	krevet	Decapoda	Hyppolitidae	0	100	0	0
10031	Леббеус лонгидактила	Lebbeus longidactyla	krevet	Decapoda	Hyppolitidae	0	100	0	0
10032	Леббеус бревипес	Lebbeus brevipes	krevet	Decapoda	Hyppolitidae	0	100	0	0
10033	Леббеус грандимана	Lebbeus grandimana	krevet	Decapoda	Hyppolitidae	0	100	0	0
10034	Леббеус гетерохета	Lebbeus heterochaeta	krevet	Decapoda	Hyppolitidae	0	100	0	0
10035	Леббеус полярис	Lebbeus polaris	krevet	Decapoda	Hyppolitidae	0	100	0	0
10036	Леббеус уналяскиенсис охотенсис	Lebbeus unalaskiensis ochotensis	krevet	Decapoda	Hyppolitidae	0	100	0	0
10037	Леббеус уналяскиенсис японика	Lebbeus unalaskiensis japonica	krevet	Decapoda	Hyppolitidae	0	100	0	0
10038	Еуалус пусиола	Eualus pusiola	krevet	Decapoda	Pandalidae	0	100	0	0
10039	Еуалус авина	Eualus avina	krevet	Decapoda	Pandalidae	0	100	0	0
10040	Еуалус биунгиус	Eualus biungius	krevet	Decapoda	Pandalidae	0	100	0	0
10041	Еуалус ратманови	Eualus ratmanovi	krevet	Decapoda	Pandalidae	0	100	0	0
10042	Еуалус гаимарди бельхери	Eualus gaimardi belcheri	krevet	Decapoda	Pandalidae	0	100	0	0
10043	Еуалус саклейи	Eualus suckleyi	krevet	Decapoda	Pandalidae	0	100	0	0
10044	Еуалус товнсенди	Eualus townsendi	krevet	Decapoda	Pandalidae	0	100	0	0
10045	Еуалус миддендорфии	Eualus middendorffi	krevet	Decapoda	Pandalidae	0	100	0	0
10046	Еуалус лептогната	Eualus leptognatha	krevet	Decapoda	Pandalidae	0	100	0	0
10047	Еуалус фабриции	Eualus fabricii	krevet	Decapoda	Pandalidae	0	100	0	0
10048	Спиронтокарис спина интермедиа	Spirontocaris spina intermedia	krevet	Decapoda	Pandalidae	0	101	0	0
10049	Спиронтокарис прионота	Spirontocaris prionota	krevet	Decapoda	Pandalidae	0	102	0	0
10050	Спиронтокарис ламелликорнис	Spirontocaris lamellicornis	krevet	Decapoda	Pandalidae	0	103	0	0
10051	Спиронтокарис мурдочи	Spirontocaris murdochi	krevet	Decapoda	Pandalidae	0	104	0	0
10052	Спиронтокарис бревидигитата	Spirontocaris brevidigitata	krevet	Decapoda	Pandalidae	0	105	0	0
10053	Спиронтокарис аркуата	Spirontocaris arcuata	krevet	Decapoda	Pandalidae	0	106	0	0
10054	Спиронтокарис спина левиденс	Spirontocaris spina laevidens	krevet	Decapoda	Pandalidae	0	107	0	0
10055	Спиронтокарис бражникови	Spirontocaris brashnikovi	krevet	Decapoda	Pandalidae	0	108	0	0
10056	Спиронтокарис фиппсии	Spirontocaris phippsii	krevet	Decapoda	Pandalidae	0	109	0	0
10057	Спиронтокарис охотенсис охотенсис	Spirontocaris ochotensis ochotensis	krevet	Decapoda	Pandalidae	0	110	0	0
10058	Спиронтокарис охотенсис морорани	Spirontocaris ochotensis mororani	krevet	Decapoda	Pandalidae	0	111	0	0
10059	Спиронтокарис макарови спатула	Spirontocaris makarovi spatula	krevet	Decapoda	Pandalidae	0	112	0	0
725	Ламинария прижатая	Laminaria appressirhiza	algae			0	0	0	0
726	Ламинария сахаристая (морская кап)	Laminaria saccharina	algae			0	0	0	0
727	Ламинария узкая	Laminaria angustata	algae			0	0	0	0
728	Ламинария цикоревидная	Laminaria circhorioides	algae			0	0	0	0
729	Ламинария японская	Laminaria japonica	algae			0	0	0	0
730	Лессония ламинаревидная	Lessonia laminarioides	algae			0	0	0	0
731	Польвеция Райта	Pelvetia wrightii	algae			0	0	0	0
732	Саргассум бледный	Sargassum pallidum	algae			0	0	0	0
733	Талассиофиллум решетчатый	Thalassiophyllum clathrus	algae			0	0	0	0
734	Фукус двухрядный	Fucus distichus	algae			0	0	0	0
735	Фукус зубчатый	Fucus serratus	algae			0	0	0	0
776	Энтероморфа	Enteromorpha sp.	algae			0	0	0	0
10070	Гребешок бело-розовый	Chlamys chosenica	pelecipoda	Pectinida	Pectinidae	0	300	0	0
10071	Гребешок беринговоморский	Chlamys behringiana	pelecipoda	Pectinida	Pectinidae	0	100	0	0
10072	Гребешок исландский	Chlamys islandica	pelecipoda	Pectinida	Pectinidae	0	140	0	0
10073	Гребешок приморский	Mizuhopecten (Patinopecten) yessoensis	pelecipoda	Pectinida	Pectinidae	0	300	0	0
10074	Гребешок светлый	Chlamys albida	pelecipoda	Pectinida	Pectinidae	0	100	0	0
10075	Гребешок японский	Chlamys farreri nipponensis	pelecipoda	Pectinida	Pectinidae	0	100	0	0
10076	Корбикула японская	Corbicula japonica	pelecipoda	Cardiida	Corbiculidae	0	80	0	0
10077	Петушок	Ruditapes philippinarus	pelecipoda	Cardiida	Veneridae	0	80	0	0
10078	Каллиста короткосифонная	Callista brevisiphonata	pelecipoda	Cardiida	Veneridae	0	80	0	0
10079	Мерценария Стимпсона	Mercenaria stimpsoni	pelecipoda	Cardiida	Veneridae	0	80	0	0
10080	Ракушка острая	Siligua alta	pelecipoda	Cardiida	Mactridae	0	80	0	0
10081	Спизула сахалинская	Spisula (Pseudocardium) sachalinensis	pelecipoda	Cardiida	Mactridae	0	80	0	0
10082	Мактра китайская	Mactra chinensis	pelecipoda	Cardiida	Mactridae	0	80	0	0
10083	Мия (Ракушка песчаная )	Mya arenaria Linnaeus, 1758	pelecipoda	Myoida	Myidae	0	80	0	0
10084	Арка Боукарда	Arca boucardi	pelecipoda	Mytilida	Arcidae	0	80	0	0
10085	Глицимерис приморский	Glycymeris yessoensis	pelecipoda	Mytilida	Glycimerididae	0	80	0	0
10086	Гребешок Свифта	Swiftopecten swifti	pelecipoda	Pectinida	Pectinidae	0	80	0	0
10087	Гребешок широкореберный	Chlamys stratega	pelecipoda	Pectinida	Pectinidae	0	80	0	0
10088	Каллитака Адамса	Callithaca adamsi	pelecipoda	Cardiida	Veneridae	0	80	0	0
10089	Мия овальная	Mya priapus	pelecipoda	Cardiida	Myidae	0	80	0	0
10090	Мия усеченная	Mya truncata	pelecipoda	Cardiida	Myidae	0	80	0	0
10091	Мия японская	Mya japonica	pelecipoda	Cardiida	Myidae	0	80	0	0
10092	Модиолус курильский	Modiolus kurilensis	pelecipoda	Mytilida	Mytilidae	0	80	0	0
10093	Мидия блестящая	Mytilus coruscus	pelecipoda	Mytilida	Mytilidae	0	80	0	0
10094	Нукуляна (Леда) обыкновенная	Nuculana pernula pernula	pelecipoda	Nuculida	Nuculidae	0	80	0	0
10095	Нутталия коммода	Nuttallia commoda	pelecipoda	Cardiida	Psammobiidae	0	80	0	0
10096	Перонидия жилковатая	Peronidia venulosa	pelecipoda	Cardiida	Tellinidae	0	80	0	0
10097	Саксикава арктическая	Saxicava (Hiatella) arctica	pelecipoda	Astartida	Hiatellidae	0	80	0	0
10098	Серцевидка калифорнийская	Clinocardium californiense	pelecipoda	Cardiida	Cardiidae	0	80	0	0
10099	Серцевидка ресничная	Clinocardium ciliatum	pelecipoda	Cardiida	Cardiidae	0	80	0	0
10100	Серрипес гренландский	Serripes groenlandicus	pelecipoda	Cardiida	Cardiidae	0	80	0	0
10101	Серрипес Лаперуза	Serripes laperosi	pelecipoda	Cardiida	Cardiidae	0	80	0	0
10102	Силиква острая	Siligua alta	pelecipoda			0	80	0	0
10103	Спизула Войи	Spisula voyi (=Mactromeris polynima)	pelecipoda	Cardiida	Mactridae	0	80	0	0
10104	Теллина розовая	Tellina lutea (Peronidia lutea)	pelecipoda	Cardiida	Tellinidae	0	80	0	0
10105	Черенок узкий	Solen strictus	pelecipoda	Cardiida	Solenidae	0	80	0	0
10106	Макома балтийская	Macoma balthica	pelecipoda	Cardiida	Tellinidae	0	100	0	0
10107	Макома контабулята	Macoma contabulata	pelecipoda	Cardiida	Tellinidae	0	100	0	0
10108	Макома известковая	Macoma calcarea	pelecipoda	Cardiida	Tellinidae	0	100	0	0
10109	Мия (Ракушка песчаная )	Mya arenaria	pelecipoda	Cardiida	Myidae	0	80	0	0
10110	Скафарка неравностворчатая	Anadara inaequivalvis	pelecipoda	Mytilida	Arcidae	0	70	0	0
10111	Серрипес замечательный	Yagudinella notabilis	pelecipoda	Cardiida	Cardiidae	0	70	0	0
10112	Модиолус обыкновенный	Modiolus modiolus	pelecipoda	Mytilida	Mytilidae	0	90	0	0
10113	Сердцевидка нутталли	Clinocardium nuttallii	pelecipoda	Cardiida	Cardiidae	0	60	0	0
10115	Сердцевидка Ламарка	Cerastoderma lamarckii	pelecipoda	Cardiida	Cardiidae	0	60	0	0
10116	Мактра прекрасная	Mactra veneriformis	pelecipoda	Cardiida	Mactridae	0	100	0	0
10117	Макома миддендорфа	Macoma middendorffii	pelecipoda	Cardiida	Tellinidae	0	100	0	0
10118	Тридонта северная	Tridonta borealis	pelecipoda	Astartida	Astartidae	0	120	0	0
10119	Тридонта ролланда	Tridonta rollandi	pelecipoda	Astartida	Astartidae	0	120	0	0
10120	Анцистролеписы	Ancistrolepis	pelecipoda			0	80	0	0
10520	Сердцевидка антарктическая	Cyclocardia astartoides	pelecipoda			0	60	0	0
10521	Латернула антарктическая	Laternula elliptica	pelecipoda			0	100	0	0
10522	Лимопсис антарктический	Limopsis marionensis	pelecipoda			0	100	0	0
10523	Маллетия кергеленская	Malletia gigantea	pelecipoda			0	100	0	0
10524	Мидия ребристая	Aulacomya ater	pelecipoda			0	200	0	0
10525	Мидия кергеленская	Mytilus edulis desolationis	pelecipoda			0	100	0	0
10526	Портландия кергеленская	Portlandia isonota	pelecipoda			0	8	0	0
10527	Йолдия антарктическая	Yoldia eightsi	pelecipoda			0	8	0	0
10528	Гребешок антарктический	Adamussium colbecki	pelecipoda			0	100	0	0
10214	Сепиетта Петерса	Sepietta petersi (Steenstrup, 1887)	squid	Sepiida		0	200	0	0
10215	Сепиетта Оуэна	Sepietta oweniana (d' Orbigny, 1839)	squid	Sepiida		0	200	0	0
10216	Эупримна Берри	Euprimna berryi Sasaki, 1929	squid	Sepiida		0	200	0	0
10217	Эупримна Морса	Еuprymna morsei (Verrill, 1881)	squid	Sepiida		0	200	0	0
10218	Сепиола атлантическая	Sepiola atlantica d'Orbigny, 1839	squid	Sepiida		0	200	0	0
10219	Сепиола двурогая	Sepiola birostrata Sasaki, 1918	squid	Sepiida		0	200	0	0
10220	Сепиола карликовая	Sepiola rondeleti Leach, 1817	squid	Sepiida		0	200	0	0
10221	Ронделетиола	Rondeletiola minor (Naef, 1912)	squid	Sepiida		0	200	0	0
10222	Семироссия патагонская	Semirossia tenera (Verrill, 1880)	squid	Sepiida		0	200	0	0
10223	Семироссия Жанна	Semirossia zhanna Arkhipkin, 2000	squid	Sepiida		0	100	0	0
10224	Неороссия	Neorossia caroli (Joubin, 1902)	squid	Sepiida		0	200	0	0
10225	Каракатица - россия тихоокеанская	Rossia pacifica Berry, 1911	squid	Sepiida		0	200	0	0
10269	Каракатица трезубцевая	Sepia trygonina (Rochebrune, 1884)	squid	Sepiida		0	400	0	0
10226	Каракатица - россия дальневосточная	Rossia mollicella Sasaki, 1920	squid	Sepiida		0	200	0	0
10227	Каракатица - россия гигантская	Rossia macrosoma (delle Chiaje, 1829)	squid	Sepiida		0	200	0	0
10228	Каракатица - россия арктическая	Rossia palpebrosa Owen, 1834	squid	Sepiida		0	200	0	0
10229	Сепиелла атлантическая	Sepiella ornata (Rang, 1837)	squid	Sepiida		0	400	0	0
10230	Сепиелла индийская	Sepiella inermis (Ferussac et d'Orbigny, 1835)	squid	Sepiida		0	300	0	0
10231	Сепиелла японская	Sepiella japonica Sasaki, 1929	squid	Sepiida		0	300	0	0
10232	Сепиадариум японский	Sepiadarium nipponianum Berry, 1932	squid	Sepiida		0	100	0	0
10233	Сепиадариум аустринум	Sepiadarium austrinum Berry, 1921	squid	Sepiida		0	100	0	0
10234	Сепиадариум грацилис	Sepiadarium gracilis Voss, 1962	squid	Sepiida		0	100	0	0
10235	Сепиадариум Кочи	Sepiadarium kochii Steenstrup, 1881	squid	Sepiida		0	100	0	0
10236	Сепиадариум ауритум	Sepiadarium auritum Robson, 1914	squid	Sepiida		0	100	0	0
10237	Сепиолодиея линейчатая	Sepioloidea lineolata (Quoy et Gaimard, 1832)	squid	Sepiida		0	100	0	0
10238	Сепиолоидея тихоокеанская	Sepioloidea pacifica (Kirk, 1882)	squid	Sepiida		0	100	0	0
10239	Каракатица Прашада	Sepia prashadi Winckworth, 1936	squid	Sepiida		0	500	0	0
10240	Каракатица звездоносная	Sepia stellifera Khromov, 1991	squid	Sepiida		0	500	0	0
10241	Каракатица кривошипая	Sepia recurvirostra Steenstrup, 1875	squid	Sepiida		0	500	0	0
10242	Каракатица Савиньи	Sepia savignyi Blainville, 1827	squid	Sepiida		0	500	0	0
10243	Каракатица пятнистая	Sepia lycidas Gray, 1849	squid	Sepiida		0	500	0	0
10244	Каракатица короткорукая	Sepia brevimana Steenstrup, 1875	squid	Sepiida		0	500	0	0
10245	Каракатица занзибарская	Sepia zanzibarica Pfeffer, 1884	squid	Sepiida		0	500	0	0
10246	Каракатица колючая	Sepia aculeata d'Orbigny, 1848	squid	Sepiida		0	500	0	0
10371	Кальмар гигантский	Architeuthis dux	squid	Teuthida		0	5500	0	0
10247	Каракатица золотистая	Sepia esculenta Hoyle, 1885	squid	Sepiida		0	500	0	0
10248	Каракатица фараонова	Sepia pharaonis Ehrenberg, 1831	squid	Sepiida		0	500	0	0
10249	Каракатица южноафриканская	Sepia simoniana Thiele, 1920	squid	Sepiida		0	500	0	0
10250	Каракатица местус	Sepia mestus Gray, 1849	squid	Sepiida		0	500	0	0
10251	Каракатица розелла	Sepia rozella (Iredale, 1926)	squid	Sepiida		0	500	0	0
10252	Каракатица гигантская австралийская	Sepia араmа Gray, 1849	squid	Sepiida		0	1200	0	0
10253	Каракатица большерукая	Sepia latimanus Quoy et Gaimard, 1832	squid	Sepiida		0	400	0	0
10254	Каракатица обыкновенная	Sepia officinalis Quoy et Gaimard, 1832	squid	Sepiida		0	400	0	0
10255	Каракатица африканская	Sepia bertheloti d'Orbigny, 1838	squid	Sepiida		0	400	0	0
10256	Каракатица гиеронис	Sepia hieronis (Robson, 1924)	squid	Sepiida		0	400	0	0
10257	Каракатица восточноафриканская	Sepia acuminata Smith, 1916	squid	Sepiida		0	400	0	0
10258	Каракатица Мадоки	Sepia madokai Adam, 1939	squid	Sepiida		0	400	0	0
10259	Каракатица Орбиньи	Sepia orbignyana Ferussac, 1826	squid	Sepiida		0	400	0	0
10260	Каракатица изящная	Sepia elegans d'Orbigny, 1826	squid	Sepiida		0	400	0	0
10261	Каракатица царская	Sepia rex (Iredale, 1926)	squid	Sepiida		0	400	0	0
10262	Каракатица южная	Sepia australis Quoy et Gaimard, 1832	squid	Sepiida		0	400	0	0
10263	Каракатица оманская	Sepia omani Adam et Rees, 1966	squid	Sepiida		0	400	0	0
10264	Каракатица арабская	Sepia arabica Massy, 1916	squid	Sepiida		0	400	0	0
10265	Каракатица длиннорукая японская	Sepia longipes Sasaki, 1914	squid	Sepiida		0	400	0	0
10266	Каракатица хвостатая	Sepia confusa Smith, 1916	squid	Sepiida		0	400	0	0
10267	Каракатица булаворукая	Sepia lorigera Wulker, 1910	squid	Sepiida		0	400	0	0
10268	Каракатица длиннорукая африканская	Sepia incerta Smith, 1916	squid	Sepiida		0	400	0	0
10270	Каракатица Андре	Sepia andreana Steenstrup, 1875	squid	Sepiida		0	400	0	0
10271	Каракатица коби	Sepia kobiensis Hoyle, 1885	squid	Sepiida		0	400	0	0
10272	Каракатица токийская	Sepia tokioensis Ortmann, 1888	squid	Sepiida		0	400	0	0
10273	Каракатица - метасепия Пфеффера	Metasepia pfefferi Hoyle, 1885	squid	Sepiida		0	100	0	0
10274	Каракатица - метасепия Тульберга	Metasepia tullbergi Appellof, 1886	squid	Sepiida		0	100	0	0
10275	Каракатица - гемисепиус обыкновенный	Hemisepius typica (Steenstrup, 1875)	squid	Sepiida		0	50	0	0
10276	Каракатица - гемисепиус африканский	Hemisepius dubia Adam et Rees, 1966	squid	Sepiida		0	50	0	0
10277	Кальмар - лолиго обыкновенный	Loligo vulgaris (Lamarck, 1798)	squid	Teuthida		0	400	0	0
10278	Кальмар - лолиго южноафриканский	Loligo reynaudi d'Orbigny, 1845	squid	Teuthida		0	400	0	0
10279	Кальмар - лолиго суринамский	Loligo surinamensis Voss, 1874	squid	Teuthida		0	400	0	0
10280	Кальмар - лолиго большеглазый	Loligo ocula Cohen, 1976	squid	Teuthida		0	400	0	0
10281	Кальмар - лолиго ропера	Loligo roperi Cohen, 1976	squid	Teuthida		0	400	0	0
10282	Кальмар - лолиго бразильский	Loligo brasiliensis Blainville, 1823	squid	Teuthida		0	400	0	0
10283	Кальмар - лолиго северный	Loligo forbesi Steenstrup, 1856	squid	Teuthida		0	500	0	0
10284	Кальмар - лолиго индийский	Loligo duvauceli d'Orbigny, 1839	squid	Teuthida		0	400	0	0
10285	Кальмар - лолиго блекери	Loligo bleekeri Keferstein, 1866	squid	Teuthida		0	400	0	0
10286	Кальмар - лолиго мечехвостый	Loligo edulis Hoyle, 1885	squid	Teuthida		0	400	0	0
10287	Кальмар - лолиго будо	Loligo budo Wakiya et Ishikawa, 1921	squid	Teuthida		0	400	0	0
10288	Кальмар - лолиго китайский	Loligo chinensis Gray, 1849	squid	Teuthida		0	400	0	0
10289	Кальмар - лолиго японский	Loligo japonica Steenstrup in Hoyle, 1885	squid	Teuthida		0	400	0	0
10290	Кальмар - лолиго Восса	Loligo vossi Nesis, 1982	squid	Teuthida		0	400	0	0
10291	Кальмар - лолиго бека	Loligo beka Sasaki, 1929	squid	Teuthida		0	400	0	0
10292	Кальмар - лолиго коби	Loligo kobiensis Hoyle, 1885	squid	Teuthida		0	400	0	0
10293	Кальмар - лолиго йокойе	Loligo yokoyae Ishikawa, 1925	squid	Teuthida		0	400	0	0
10294	Кальмар - лолиго тагои	Loligo tagoi Sasaki, 1829	squid	Teuthida		0	400	0	0
10295	Кальмар - лолиго южнокитайский	Loligo uyii Wakiya et Ishikawa, 1921	squid	Teuthida		0	400	0	0
10296	Кальмар - лолиго аспера	Loligo aspera Ortmann, 1888	squid	Teuthida		0	400	0	0
10297	Кальмар - лолиго цейлонский	Loligo singhalensis Ortman, 1891	squid	Teuthida		0	400	0	0
10298	Кальмар - лолиго арабский	Loligo arabica (Ehrenberg, 1831)	squid	Teuthida		0	400	0	0
10299	Кальмар - лолиго спектрум	Loligo spectrum Pfeffer, 1884	squid	Teuthida		0	400	0	0
10300	Кальмар - лолиго Пикфорда	Loligo pickfordae Adam, 1955	squid	Teuthida		0	400	0	0
10301	Кальмар - лолиго сибога	Loligo sibogae Adam, 1954	squid	Teuthida		0	400	0	0
10302	Кальмар - лолиго филиппинский	Loligo reesei Voss, 1963	squid	Teuthida		0	400	0	0
10303	Кальмар - доритеутис патагонский	Doryteuthis patagonica Smith, 1881	squid	Teuthida		0	400	0	0
10304	Кальмар - доритеутис гахи	Doyteuthis gahi d'Orbigny, 1835	squid	Teuthida		0	400	0	0
10305	Кальмар - доритеутис санпаулензис	Doryteuthis sanpaulensis (Brakoniecki, 1984)	squid	Teuthida		0	400	0	0
10306	Кальмар - доритеутис плеи	Doryteuthis plei (Blainville, 1823)	squid	Teuthida		0	400	0	0
10307	Кальмар - доритеутис восточноамериканский	Doryteuthis pealei LeSueur 1821	squid	Teuthida		0	400	0	0
10308	Кальмар - доритеутис калифорнийский	Doryteuthis opalescence Berry, 1911	squid	Teuthida		0	400	0	0
10309	Кальмар - аллотеутис средний	Alloteuthis media (Linneus, 1758)	squid	Teuthida		0	400	0	0
10310	Кальмар - аллотеусти европейский	Alloteuthis subulata (Lamarck, 1798)	squid	Teuthida		0	400	0	0
10311	Кальмар - аллотеусти африканский	Alloteuthis africana Adam, 1950	squid	Teuthida		0	400	0	0
10312	Кальмар каракатицевидный южный	Sepioteuthis australis Quoy et Gaimard, 1832	squid	Teuthida		0	400	0	0
10313	Кальмар каракатицевидный обыкновенный	Sepioteuthis lessoniana Lesson, 1830	squid	Teuthida		0	400	0	0
10314	Кальмар каракатицевидный американский	Sepioteuthis sepioidea (Blainville, 1823)	squid	Teuthida		0	400	0	0
10315	Кальмар - лолиолус японский	Loliolus (Nipponololigo) japonica (Hoyle, 1885)	squid	Teuthida		0	300	0	0
10316	Кальмар - лолиолус аффинис	Loliolus affinis (Steenstrup, 1856)	squid	Teuthida		0	300	0	0
10317	Кальмар - лолиолус Хардвика	Loliolus hardwickei (Gray, 1949)	squid	Teuthida		0	300	0	0
10318	Лоллигункула короткая	Lolliguncula brevis (Blainville, 1823)	squid	Teuthida		0	300	0	0
10319	Лоллигункула панамская	Lolliguncula panamensis Berry, 1911	squid	Teuthida		0	300	0	0
10320	Кальмар - лолиолопсис	Loliolopsis diomedeae (Hoyle, 1904)	squid	Teuthida		0	300	0	0
10321	Кальмар - лолиго короткорукий	Heterololigo bleekeri (Keferstein, 1866)	squid	Teuthida		0	300	0	0
10322	Кальмар - уротеутис цейлонский	Uroteuthis singhalensis (Ortmann, 1891)	squid	Teuthida		0	300	0	0
10323	Кальмар - уротеутис тонкий	Uroteuthis bartschi (Render, 1945)	squid	Teuthida		0	300	0	0
10324	Кальмар - эстуариолус	Aestuariolus noctiluca (Lu,Roper,Tait, 1985)	squid	Teuthida		0	300	0	0
10325	Кальмар - лолиго гвинейский	Afrololigo mercatoris (Adam, 1941)	squid	Teuthida		0	300	0	0
10326	Кальмар - пикфордиотеутис	Pickfordiateuthis pulchella Voss, 1953	squid	Teuthida		0	200	0	0
10327	Кальмар мягкотелый, антарктический	Alluroteuthis antarcticus Odhner, 1923	squid	Teuthida		0	360	0	0
10328	Кальмар - неотеутис Тиля	Neoteuthis thielei Naef, 1921	squid	Teuthida		0	300	0	0
10329	Кальмар - шилохвост антарктический	Batoteuthis skolops Young et Roper, 1968	squid	Teuthida		0	300	0	0
10330	Кальмар - батитеутис абиссальный	Bathyteuthis abyssicola Hoyle, 1885	squid	Teuthida		0	100	0	0
10331	Кальмар - брахиотеутис обыкновенный	Brachioteuthis riisei (Steenstrup, 1882)	squid	Teuthida		0	200	0	0
10332	Кальмар - брахиотеутис пестрый	Brachioteuthis picta Chun, 1910	squid	Teuthida		0	140	0	0
10333	Кальмар - циклотеутис Акимушкина	Cycloteuthis akimushkini Filippova, 1968	squid	Teuthida		0	600	0	0
10334	Кальмар - циклотеутис сирвента	Cycloteuthis sirventi Joubin, 1919	squid	Teuthida		0	600	0	0
10335	Кальмар - дискотеутис круглый	Discoteuthis discus Young et Roper, 1969	squid	Teuthida		0	400	0	0
10336	Кальмар - дискотеутис лациниоза	Discoteuthis laciniosa Young et Roper, 1969	squid	Teuthida		0	400	0	0
10337	Кальмар - Верании	Chiroteuthis veranyi (Ferrusac, 1835)	squid	Teuthida		0	400	0	0
10338	Кальмар - хиротеутис Жубена	Chiroteuthis joubini Voss, 1967	squid	Teuthida		0	400	0	0
10339	Кальмар - хиротеутис тиоокеанский	Chiroteuthis calyx Young, 1972	squid	Teuthida		0	400	0	0
10340	Кальмар хиротеутис пикта	Chiroteuthis picteti Joubin, 1894	squid	Teuthida		0	400	0	0
10341	Кальмар - хиротеутис капенсис	Chiroteuthis capensis Voss, 1967	squid	Teuthida		0	400	0	0
10342	Кальмар - вальбитеутис Дана	Valbyteuthis danae Joubin 1931	squid	Teuthida		0	400	0	0
10343	Кальмар - вальбитеутис широкий	Valbyteuthis oligobessa Young, 1972	squid	Teuthida		0	400	0	0
10344	Кальмар - вальбитеутис длиннорукий	Valbyteuthis levimana (Loenberg, 1896)	squid	Teuthida		0	400	0	0
10345	Кальмар - мастигопсис Хьорта	Mastigopsis hjorti Chun, 1913	squid	Teuthida		0	300	0	0
10346	Кальмар биченосный Гримальда	Mastigoteuthis grimaldii (Joubin,1 1895)	squid	Teuthida		0	400	0	0
10347	Кальмар биченосный индопацифический	Mastigoteuthis dentata Hoyle, 1904	squid	Teuthida		0	400	0	0
10348	Кальмар биченосный калифорнийский	Mastigoteuthis pyrodes Young, 1972	squid	Teuthida		0	400	0	0
10349	Кальмар биченосный Шмидта	Mastigoteuthis schmidti Degner, 1925	squid	Teuthida		0	400	0	0
10350	Кальмар биченосный антарктический	Mastigoteuthis psychrophila Nesis, 1977	squid	Teuthida		0	400	0	0
10351	Кальмар биченосный красный	Mastigoteuthis flamnea Chun, 1908	squid	Teuthida		0	400	0	0
10352	Кальмар биченосный Агациса	Mastigoteuthis agassizi Verrill, 1881	squid	Teuthida		0	400	0	0
10353	Кальмар биченосный азорский	Mastigoteuthis talismani (Fischer et Joubin, 1906)	squid	Teuthida		0	400	0	0
10354	Кальмар биченосный атлантический	Mastigoteuthis atlantica Joubin, 1933	squid	Teuthida		0	400	0	0
10355	Кальмар биченосный глаукопсис	Mastigoteuthis glaucopsis Chun, 1908	squid	Teuthida		0	400	0	0
10356	Кальмар биченосный сердцевидный	Mastigoteuthis cordiformis Chun, 1908	squid	Teuthida		0	300	0	0
10357	Кальмар биченосный магна	Mastigoteuthis magna Joubin, 1913	squid	Teuthida		0	400	0	0
10358	Кальмар биченосный инермис	Mastigoteuthis inermis Rancurel, 1972	squid	Teuthida		0	400	0	0
10359	Кальмар биченосный латипинна	Mastigoteuthis latipinna (Sasaki, 1916)	squid	Teuthida		0	400	0	0
10360	Кальмар лучеперый обыкновенный	Chtenopteryx sicula (Verany, 1851)	squid	Teuthida		0	150	0	0
10361	Кальмар лучеперый сепиоидный	Chtenopteryx sepioides Rancurel, 1970	squid	Teuthida		0	150	0	0
10362	Кальмар двуплавниковый	Grimalditeuthis bonplandi (Verany, 1837)	squid	Teuthida		0	200	0	0
10363	Кальмар иглохвостый	Joubiniteuthis portieri Joubin, 1912	squid	Teuthida		0	300	0	0
10364	Кальмар - промахотеутис большекрылый	Promachoteuthis megaptera Hoyle,1885	squid	Teuthida		0	100	0	0
10365	Кальмар восьмирукий морщинистый	Octopoteuthis rugosa Clarke, 1980	squid	Teuthida		0	400	0	0
10366	Кальмар восьмирукий Дана	Octopoteuthis danae Joubin, 1931	squid	Teuthida		0	1000	0	0
10367	Кальмар восьмирукий делетрон	Octopoteuthis deletron Young, 1972	squid	Teuthida		0	1000	0	0
10368	Кальмар восьмирукий большекрылый	Octopoteuthis megaptera (Verrill, 1885)	squid	Teuthida		0	1000	0	0
10369	Кальмар восьмирукий сикула	Octopoteuthis sicula (Roeppell, 1844)	squid	Teuthida		0	1000	0	0
10370	Кальмар танингия	Taningia danae Joubin,1931	squid	Teuthida		0	1200	0	0
10372	Кальмар аргентинский короткоперый	Illex argentinus (Castellanos,1960)	squid	Teuthida		0	500	0	0
10373	Кальмар короткоперый средиземноморский	Illex coindetii (Verany, 1837)	squid	Teuthida		0	400	0	0
10374	Кальмар короткоперый североатлантический	Illex illecebrosus (LeSueur, 1821)	squid	Teuthida		0	400	0	0
10375	Кальмар-мартиалия	Martialia hyadesi Rochebrune et Mabille, 1887	squid	Teuthida		0	550	0	0
10376	Кальмар тодаропсис	Todaropsis eblanae (Ball, 1841)	squid	Teuthida		0	400	0	0
10377	Кальмар тихоокеанский	Todarodes pacificus Steenstrup, 1880	squid	Teuthida		0	500	0	0
10378	Кальмар-стрелка северный	Todarodes sagittatus	squid	Teuthida		0	500	0	0
10379	Кальмар - тодародес Филипповой	Todarodes filippovae Adam, 1975	squid	Teuthida		0	600	0	0
10380	Кальмар - стрелка северный	Todarodes sagittatus (Lamarck, 1799)	squid	Teuthida		0	600	0	0
10381	Кальмар - стрелка южный	Todarodes angolensis Adam, 1962	squid	Teuthida		0	600	0	0
10382	Кальмар новозеландский	Nototodarus sloani (Gray, 1849)	squid	Teuthida		0	500	0	0
10383	Кальмар гавайский	Nototodarus hawaiiensis (Berry, 1912)	squid	Teuthida		0	500	0	0
10384	Кальмар австралийский стреловидный	Nototodarus gouldi (McCoy, 1888)	squid	Teuthida		0	500	0	0
10385	Кальмар - птица антильский	Ornithoteuthis antillarum Adam, 1957	squid	Teuthida		0	500	0	0
10386	Кальмар - птица летающий	Ornithoteuthis volatilis (Sasaki, 1915)	squid	Teuthida		0	500	0	0
10387	Кальмар полосатый	Eucleoteuthis luminosa (Sasaki, 1915)	squid	Teuthida		0	400	0	0
10388	Кальмар Бартрама	Ommastrephes bartrami (LeSueur, 1821)	squid	Teuthida		0	700	0	0
10389	Кальмар - уаланиензис	Sthenoteuthis oualaniensis (Lesson, 1830)	squid	Teuthida		0	1200	0	0
10390	Кальмар крылорукий	Sthenoteuthis pteropus (Steenstrup, 1855)	squid	Teuthida		0	900	0	0
10391	Кальмар перуанский гигантский	Dosidicus gigas (d'Orbigny, 1835)	squid	Teuthida		0	2000	0	0
10392	Кальмар - гиалотеутис	Hyaloteuthis pelagica (Bosc, 1802)	squid	Teuthida		0	300	0	0
10393	Кальмар-ромб	Thysanoteuthis rhombus Troschel, 1857	squid	Teuthida		0	1500	0	0
10394	Кальмар - психротеутис ледяной	Psychroteuthis glacialis Thiele, 1920	squid	Teuthida		0	700	0	0
10395	Кальмар крючьеносный курильский	Onychoteuthis borealijaponicus Okada, 1927	squid	Teuthida		0	450	0	0
10396	Кальмар крючьеносный Банкса	Onychoteuthis banksii (Leach, 1817)	squid	Teuthida		0	450	0	0
10397	Кальмар крючьеносный тихоокеанский	Onychoteuthis meridiopacifica	squid	Teuthida		0	400	0	0
10398	Кальмар - анцистротеутис Лихтенштейна	Ancistroteuthls lichtensteini Gray, 1849	squid	Teuthida		0	400	0	0
10399	Кальмар - Кондаковия длиннорукая	Kondakovia longimana Filippova, 1972	squid	Teuthida		0	1100	0	0
10400	Кальмар - моротеутис ингенс	Moroteuthis ingens (Smith, 1881)	squid	Teuthida		0	900	0	0
10401	Кальмар - моротеутис Книповича	Moroteuthis knipovitchi Filippova, 1972	squid	Teuthida		0	600	0	0
10402	Кальмар - моротеутис японский	Moroteuthis loennbergi Ishikawa et Wakiya, 1914	squid	Teuthida		0	1000	0	0
10403	Кальмар - моротеутис крепкий	Moroteuthis robusta (Verrill, 1876)	squid	Teuthida		0	1500	0	0
10404	Кальмар - моротеустис Робсона	Moroteuthis robsoni Adam, 1962	squid	Teuthida		0	1000	0	0
10405	Кальмар - моротеутис экваториальный	Moroteuthis aequatorialis, Thiele, 1920	squid	Teuthida		0	600	0	0
10406	Кальмар - оникия карибская	Onykia carriboea LeSueur, 1821	squid	Teuthida		0	150	0	0
10407	Кальмар - вальситтеутис	Walvisteuthis rancureli Nesis, Nikitina, 1986	squid	Teuthida		0	120	0	0
10408	Кальмар - нотоникия африканская	Notonykia africanae	squid	Teuthida		0	160	0	0
10409	Кальмар - нотоникия Несиса	Notonykia nesisi	squid	Teuthida		0	160	0	0
10410	Кальмар - нерротеутис Несиса	Narroteuthis nesisi	squid	Teuthida		0	400	0	0
10411	Чешуйчатый кальмар	Lepidoteuthis grimaldii Joubin, 1895	squid	Teuthida		0	1200	0	0
10412	Кальмар - фолидотеутис Бошма	Pholidoteuthis boschmai Adam, 1950	squid	Teuthida		0	900	0	0
10414	Кальмар - фолидотеутис Масси	Pholidoteuthidae massyae	squid	Teuthida		0	900	0	0
10415	Кальмар бриллиантовый зонтичный	Histioteuthis bonnellii (Ferrusac, 1835)	squid	Teuthida		0	450	0	0
10416	Кальмар бриллиантовый перепончаторукий	Histioteuthis macrohista Voss, 1969	squid	Teuthida		0	100	0	0
10417	Кальмар бриллиантовый атлантический	Histioteuthis atlantica (Hoyle, 1885)	squid	Teuthida		0	100	0	0
10418	Кальмар бриллиантовы южный	Histioteuthis eltaninae N.Voss,1969	squid	Teuthida		0	100	0	0
10419	Кальмар бриллиантовый реверса	Histioteuthis reversa (Verrill, 1880)	squid	Teuthida		0	200	0	0
10420	Кальмар бриллиантовый удлиненный	Histioteuthis elongata Voss et Voss, 1962	squid	Teuthida		0	250	0	0
10421	Кальмар бриллиантовый Хойля	Histioteuthis hoylei (Goodrich, 18896)	squid	Teuthida		0	300	0	0
10422	Кальмар бриллиантовый целетария	Histioteuthis celetaria (Voss, 1960)	squid	Teuthida		0	300	0	0
10423	Кальмар бриллиантовый Дофлейна	Histioteuthis dofleini Pfeffer, 1912	squid	Teuthida		0	300	0	0
10424	Кальмар бриллиантовый японский	Histioteuthis inermis (Taki, 1964)	squid	Teuthida		0	300	0	0
10425	Кальмар бриллиантовы тихоокеанский	Histioteuthis pacifica (Voss, 1962)	squid	Teuthida		0	300	0	0
10426	Кальмар бриллиантовый Берри	Histioteuthis berryi Voss, 1969	squid	Teuthida		0	300	0	0
10427	Кальмар бриллиантовый красный	Histioteuthis cerasina Nesis, 1971	squid	Teuthida		0	300	0	0
10428	Кальмар бриллиантовый Бруна	Histioteuthis bruuni Voss, 1969	squid	Teuthida		0	120	0	0
10429	Кальмар бриллиантовый корона	Histioteuthis corona (Voss et Voss, 1962)	squid	Teuthida		0	250	0	0
10430	Кальмар бриллиантовый шипастый	Histioteuthis miranda (Berry, 1918)	squid	Teuthida		0	330	0	0
10431	Кальмар бриллиантовый гетеропсис	Histioteuthis heteropsis (Berry, 1913)	squid	Teuthida		0	200	0	0
10432	Кальмар бриллиантовый Мелеагр	Histioteuthis meleagroteuthis (Chun, 1910)	squid	Teuthida		0	200	0	0
10433	Кальмар командорский	Berryteuthis magister (Berry, 1913)	squid	Teuthida		0	550	0	0
10434	Кальмар аляскинский	Berryteuthis anonychus (Pearcy et Voss,1963)	squid	Teuthida		0	250	0	0
10435	Кальмар - гонатопсис японский	Gonatopsis japonicus Okiyama, 1969	squid	Teuthida		0	700	0	0
10436	Кальмар - гонатопсис северный	Gonatopsis borealis Sasaki, 1923	squid	Teuthida		0	400	0	0
10437	Кальмар - гонатопсис восьмирукий	Gonatopsis octopedatus Sasaki, 1920	squid	Teuthida		0	300	0	0
10438	Кальмар - гонатопсис макко	Gonatopsis makko Okutani et Nemoto, 1964	squid	Teuthida		0	900	0	0
10439	Кальмар - гонатус антарктический	Gonatus antarcticus Lonnberg, 1898	squid	Teuthida		0	500	0	0
10440	Кальмар - гонатус Фабрициуса	Gonatus fabricii (Lichtenstein, 1818)	squid	Teuthida		0	400	0	0
10441	Кальмар - гонатус Стенструпа	Gonatus steenstrupi Kristensen,1981	squid	Teuthida		0	300	0	0
10442	Кальмар - гонатус ониксовый	Gonatus оnух Young, 1972	squid	Teuthida		0	300	0	0
10443	Кальмар - гонатус Мадоки	Gonatus madokai Kubodera et Okutani, 1977	squid	Teuthida		0	450	0	0
10444	Кальмар - гонатус камчатский	Gonatus kamtschaticus (Middendorff, 1849)	squid	Teuthida		0	450	0	0
10445	Кальмар - гонатус светящийся	Gonatus pyros Young, 1972	squid	Teuthida		0	300	0	0
10446	Кальмар - гонатус Берри (большая дубинка)	Gonatus berryi, Neaf, 1923	squid	Teuthida		0	300	0	0
10447	Кальмар - гонатус калифорнийский	Gonatus californiensis Young, 1972	squid	Teuthida		0	250	0	0
10448	Кальмар - эогонатус тинро	Eogonatus tinro Nesis, 1972	squid	Teuthida		0	180	0	0
10449	Кальмар - ликотеутис диадема	Lycoteuthis diadema (Chun, 1900)	squid	Teuthida		0	400	0	0
10450	Кальмар - селенотеутис	Selenoteuthis scintillans Voss, 1958	squid	Teuthida		0	99	0	0
10451	Кальмар - лампадиутеутис	Lampadioteuthis megaleia Berry, 1916	squid	Teuthida		0	99	0	0
10453	Кальмар - светлячок японский	Watasenia scintillans (Berry, 1911)	squid	Teuthida		0	100	0	0
10454	Кальмар - энигмотеутис	Enigmoteuthis dubia Adam, 1973	squid	Teuthida		0	80	0	0
10455	Кальмар - светлячок Лезуэра	Ancistrocheirus lesueuri (Ferussac et d'Orbigny, 1839)	squid	Teuthida		0	400	0	0
10456	Кальмар - светлячок большекрылый	Ancistrocheirus alessandrinii (Verany, 1851)	squid	Teuthida		0	400	0	0
10457	Кальмар - еноплотеутис анаспис	Enoploteuthis anaspis Roper, 1964	squid	Teuthida		0	200	0	0
10458	Кальмар - еноплотеутис лептура	Enoploteuthis leptura (Leach, 1817)	squid	Teuthida		0	200	0	0
10459	Кальмар - еноплотеутис Хуна	Enoploteuthis chuni Ishikawa, 1914	squid	Teuthida		0	200	0	0
10460	Кальмар - еноплотеутис галаксис	Enoploteuthis galaxias Berry, 1918	squid	Teuthida		0	200	0	0
10461	Кальмар - еноплотеутис сетчатый	Enoploteuthis reticulata Rancurel, 1970	squid	Teuthida		0	200	0	0
10462	Кальмар - абралия армата	Abralia armata (Quoy et Gaimard, 1832)	squid	Teuthida		0	200	0	0
10463	Кальмар - стенабралия астролинеата	Stenabralia astrolineata Berry, 1914	squid	Teuthida		0	200	0	0
10464	Кальмар - стенабралия астростикта	Stenabralia astrosticta Berry, 1909	squid	Teuthida		0	200	0	0
10465	Кальмар - стенабралия ренши	Stenabralia renschi Grimpe, 1931	squid	Teuthida		0	200	0	0
10466	Кальмар - стенабралия люценс	Stenabralia lucens Voss, 1962	squid	Teuthida		0	200	0	0
10467	Кальмар - стенабралия Спэрка	Stenabralia spaercki Grimpe, 1931	squid	Teuthida		0	200	0	0
10468	Кальмар - астеротеутис Гримпа	Asteroteuthis grimpei Voss, 1958	squid	Teuthida		0	200	0	0
10469	Кальмар - астеротеутис китайский	Asteroteuthis multihamata Sasaki, 1929	squid	Teuthida		0	200	0	0
10470	Кальмар - астеротеутис Верани	Asteroteuthis veranyi Roeppell, 1844	squid	Teuthida		0	200	0	0
10471	Кальмар - астеротеутис андаманский	Asteroteuthis andamanica Goodrich, 1896	squid	Teuthida		0	200	0	0
10472	Кальмар - астеротеутис японский	Asteroteuthis japonica Ishikawa, 1929	squid	Teuthida		0	200	0	0
10473	Кальмар - астеротеутис Редфилда	Asteroteuthis redfieldi Voss, 1955	squid	Teuthida		0	200	0	0
10474	Кальмар - абралиопсис Хойля	Abraliopsis hoylei (Pfeffer, 1884)	squid	Teuthida		0	90	0	0
10475	Кальмар - абралиопсис кошачий	Abraliopsis felis McGowan et Okutani, 1968	squid	Teuthida		0	90	0	0
10476	Кальмар - микрабралия Джилкриста	Micrabralia gilchristi (Robson, 1924)	squid	Teuthida		0	90	0	0
10477	Кальмар - микрабралия калифорнийская	Micrabralia affinis (Pfeffer, 1912)	squid	Teuthida		0	90	0	0
10478	Кальмар - микрабралия Хуна	Micrabralia chuni Nesis, 1982	squid	Teuthida		0	90	0	0
10479	Кальмар - микрабралия линейный	Micrabralia lineata (Goodrich, 1896)	squid	Teuthida		0	90	0	0
10480	Кальмар - микрабралия фалько	Micrabralia falco Young, 1972	squid	Teuthida		0	90	0	0
10481	Кальмар - микрабралия атлантическая	Micrabralia atlantica Nesis, 1982	squid	Teuthida		0	90	0	0
10482	Кальмар - пиротеутис маргаритифера	Pyroteuthis margaritifera (Roeppell, 1844)	squid	Teuthida		0	90	0	0
10483	Кальмар - пиротеутис аддолюкс	Pyroteuthis addolux Young, 1972	squid	Teuthida		0	90	0	0
10484	Кальмар - птеригиотеутис геммата	Pterygioteuthis gemmata Chun, 1908	squid	Teuthida		0	90	0	0
10485	Кальмар - птеригиотеутис Гьярда	Pterygioteuthis giardiFische, 1896	squid	Teuthida		0	90	0	0
10486	Кальмар антарктический колоссальный	Mesonychoteuthis hamiltoni Robson, 1925	squid	Teuthida		0	4000	0	0
10487	Кальмар - галитеутис антарктический	Galiteuthis glacialis (Chun, 1906)	squid	Teuthida		0	600	0	0
10488	Кальмар - галитеутис филлюра	Galiteuthis phyllura Berry, 1911	squid	Teuthida		0	600	0	0
10489	Кальмар - галитеутис армата	Galiteuthis armata Joubin, 1898	squid	Teuthida		0	500	0	0
10490	Кальмар - галитеутис натальный	Galiteuthis sumi (Hoyle, 1885)	squid	Teuthida		0	500	0	0
10499	Кальмар - теутовения Ричардсона	Teuthowenia richardsoni (Dell, 1959)	squid	Teuthida		0	400	0	0
10500	Кальмар - геликокранхия Пфеффера	Helicocranchia pfefferi Massy, 1907	squid	Teuthida		0	400	0	0
10501	Кальмар - геликокранхия папиллята	Helicocranchia papillata (Voss, 1960)	squid	Teuthida		0	400	0	0
10502	Кальмар - личия эллипсоптера	Leachia ellipsoptera Adams et Reve, 1845	squid	Teuthida		0	300	0	0
10504	Кальмар - пиргопсис атлантический	Pyrgopsis atlantica (Degner, 1925)	squid	Teuthida		0	300	0	0
10505	Кальмар - пиргопсис тихоокеанский	Pyrgopsis pacifica (Issel, 1908)	squid	Teuthida		0	300	0	0
10506	Кальмар - пиргопсис ринхофорус	Pyrgopsis rynchophorus Rochebrune, 1884	squid	Teuthida		0	300	0	0
10507	Кальмар - лиокранхия Рейнхардта	Liocranchia reinhardti (Steenstrup, 1856)	squid	Teuthida		0	300	0	0
10508	Кальмар - лиокранхия Вальдивия	Liocranchia valdiviae Chun, 1906	squid	Teuthida		0	300	0	0
10509	Кальмар - батискаф	Cranchia scabra Leach, 1817	squid	Teuthida		0	200	0	0
10510	Кальмар - игия инермис	Egea inermis Joubin, 1933	squid	Teuthida		0	200	0	0
10511	Кальмар - таониус	Taonius pavo (LeSueur, 1821)	squid	Teuthida		0	200	0	0
10512	Кальмар - сандалопс меланхоликус	Sandalops melancholicus Chun, 1906	squid	Teuthida		0	200	0	0
10513	Кальмар - батотаума	Bathothauma lyroma Chun, 1906	squid	Teuthida		0	200	0	0
\.


--
-- Data for Name: stations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY stations (myear, vesselcode, numsurvey, numstn, typesurvey, numjurnalstn, nlov, gearcode, vtral, datebegin, timebegin, latgradbeg, latminbeg, longradbeg, lonminbeg, depthbeg, dateend, timeend, latgradend, latminend, longradend, lonminend, depthend, depthtral, wirelength, nlovobr, bottomcode, press, t, vwind, rwind, wave, tsurface, tbottom, samplewght, observnum, cell, trapdist, formcatch, lcatch, wcatch, hcatch, nentr, kurs, observcode, ngrupspec, flagsgrup) FROM stdin;
2000	000а	1	13	1	22222	\N	11	2.5	29.09.2000	07:12	62	13.800000000000001	-179	21.699999999999999	117	29.09.2000	07:12	62	17.100000000000001	-179	18	116	22222	22222	\N	4	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	14	1	22222	\N	11	2.6000000000000001	29.09.2000	09:36	62	22	-178	40	102	29.09.2000	09:36	62	23.399999999999999	-178	32	102	22222	22222	\N	4	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2010	0001	1	3	1	22222	22222	10	12	02.11.2010	02:02	3	0	3	0	333	02.11.2010	03:03	22222	22222	22222	22222	22222	22222	22222	22222	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	22222	22222	22222	22222	22222	22222	22222	2	\N	\N
2000	000а	1	16	1	22222	\N	11	2.5	29.09.2000	06:00	62	6.4000000000000004	-176	47.799999999999997	99	29.09.2000	06:00	62	4.7000000000000002	-176	50.399999999999999	101	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2010	0001	1	2	2	22222	12	10	22222	02.11.2010	04:04	2	0	2	0	123	02.11.2010	05:05	22222	22222	22222	22222	22222	22222	22222	12	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	22222	1	22222	22222	22222	1	22222	2	\N	\N
2000	000а	1	15	1	22222	22222	11	2.6000000000000001	29.09.2000	04:48	62	10.1	-177	49.700000000000003	108	29.09.2000	04:49	62	8	-177	45.600000000000001	109	22222	22222	22222	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	22222	22222	22222	22222	22222	22222	22222	2	\N	\N
2000	000а	1	12	1	22222	22222	11	2.6000000000000001	29.09.2000	03:36	62	9.9000000000000004	179	54.5	114	29.09.2000	03:37	62	7.0999999999999996	179	53.200000000000003	110	22222	22222	22222	4	22222	22222	22222	22222	22222	22222	22222	22222	1	12	22222	22222	22222	22222	22222	22222	22222	2	\N	\N
2000	000а	1	33	1	22222	22222	11	3	04.10.2000	00:00	64	15.800000000000001	-179	56	46	04.10.2000	09:36	64	16	-179	53	46	22222	22222	22222	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	22222	22222	22222	22222	22222	22222	22222	2	\N	\N
2000	000а	2	12	1	22222	\N	11	2.6000000000000001	29.09.2000	03:36	62	9.9000000000000004	179	54.5	114	29.09.2000	03:36	62	7.0999999999999996	179	53.200000000000003	110	22222	22222	\N	4	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	13	1	22222	\N	11	2.5	29.09.2000	07:12	62	13.800000000000001	-179	21.699999999999999	117	29.09.2000	07:12	62	17.100000000000001	-179	18	116	22222	22222	\N	4	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	14	1	22222	\N	11	2.6000000000000001	29.09.2000	09:36	62	22	-178	40	102	29.09.2000	09:36	62	23.399999999999999	-178	32	102	22222	22222	\N	4	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	41	1	22222	22222	11	3	05.10.2000	00:00	64	4	-176	25	81	05.10.2000	12:00	64	5	-176	28.699999999999999	81	22222	22222	22222	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	22222	22222	22222	22222	22222	22222	22222	2	\N	\N
2000	000а	1	34	1	22222	22222	11	2.7999999999999998	04.10.2000	03:36	64	54.399999999999999	-177	46.100000000000001	60	04.10.2000	04:36	64	51.899999999999999	-177	42	60	22222	22222	22222	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	22222	22222	22222	22222	22222	22222	22222	2	\N	\N
2010	UHGK	1	1	1	22222	22222	28	2.7999999999999998	02.11.2010	12:00	46	52	137	52	256	02.11.2010	15:00	22222	22222	22222	22222	22222	22222	600	22222	0	22222	22222	22222	22222	22222	22222	22222	22222	1	10	22222	22222	22222	22222	22222	22222	22222	14	\N	\N
2008	UHGK	1	1	1	22222	22222	28	2.7999999999999998	24.04.2008	12:00	46	0	137	0	254	29.05.2008	17:00	22222	22222	22222	22222	22222	22222	22222	22222	0	22222	22222	22222	22222	22222	22222	22222	22222	1	10	22222	22222	22222	22222	22222	22222	22222	14	\N	\N
2010	УАХФ	12	2	1	5	22222	10	1	21.12.2010	12:00	89	21	141	35	129	25.12.2010	11:45	22222	22222	22222	22222	22222	100	300	22222	17	1100	12	15	127	3	5	3	123	1	45	22222	22222	22222	22222	22222	22222	22222	26	\N	\N
2010	0001	1	4	4	22222	22222	10	12	01.11.2010	01:01	1	0	1	0	111	01.11.2010	02:02	22222	22222	22222	22222	22222	22222	22222	22222	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	22222	22222	22222	22222	22222	22222	22222	2	\N	\N
2000	000а	2	48	1	22222	\N	11	2.7999999999999998	06.10.2000	12:00	63	6	-175	20	80	06.10.2000	12:00	63	3	-175	23	79	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	49	1	22222	\N	11	2.6000000000000001	07.10.2000	06:00	62	43.5	-175	45.799999999999997	80	07.10.2000	06:00	62	45.799999999999997	-175	48.700000000000003	80	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	50	1	22222	\N	11	2.6000000000000001	07.10.2000	07:12	63	3.2999999999999998	-176	9.3000000000000007	83	07.10.2000	07:12	63	2	-176	13.800000000000001	84	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	51	1	22222	\N	11	2.8999999999999999	07.10.2000	08:24	62	48	-176	58.799999999999997	90	07.10.2000	08:24	62	51.200000000000003	-177	0	90	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	52	1	22222	\N	11	2.6000000000000001	07.10.2000	06:00	63	15.199999999999999	-177	10.6	87	07.10.2000	06:00	63	13.199999999999999	-177	15.9	90	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2010	УАХФ	12	3	2	1	3	10	22222	03.07.2010	08:00	67	28.553999999999998	41	4.2560000000000002	33	03.07.2010	20:00	22222	22222	22222	22222	22222	22222	22222	3	0	22222	22222	22222	22222	22222	22222	22222	22222	1	50	200	0	22222	22222	22222	1	22222	23	\N	\N
2010	0001	1	5	3	4096	22222	10	22222	11.11.2010	01:01	1	0	1	0	22222	11.11.2010	01:01	22222	22222	22222	22222	22222	22222	22222	22222	3	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	2	\N	\N
2010	УАХФ	12	1	3	1	22222	10	22222	03.07.2010	13:15	67	9.7449999999999992	41	19.332000000000001	22222	03.07.2010	13:15	22222	22222	22222	22222	22222	22222	22222	22222	2	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	90	23	\N	\N
2000	000а	1	17	1	22222	\N	11	2.5	29.09.2000	04:48	61	54	-177	9	112	29.09.2000	04:48	61	52.200000000000003	-177	14	114	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	18	1	22222	\N	11	2.6000000000000001	29.09.2000	04:48	61	49	-177	16	130	29.09.2000	04:48	61	51.5	-177	13.199999999999999	122	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	19	1	22222	\N	11	2.5	30.09.2000	02:24	61	34.600000000000001	-178	0.40000000000000002	143	30.09.2000	02:24	61	32.200000000000003	-178	1.8	148	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	20	1	22222	\N	11	2.5	30.09.2000	12:00	62	4	-178	14	113	30.09.2000	12:00	62	6.5	-178	14.4	111	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	21	1	22222	\N	11	2.6000000000000001	30.09.2000	06:00	62	37.799999999999997	-178	6.9000000000000004	94	30.09.2000	06:00	62	38.5	-178	12	94	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	22	1	22222	\N	11	2.5	30.09.2000	09:36	62	44.5	-178	53.799999999999997	92	30.09.2000	09:36	62	45.399999999999999	-178	59.899999999999999	92	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	23	1	22222	\N	11	2.5	30.09.2000	07:12	62	48.799999999999997	-179	34.899999999999999	86	30.09.2000	07:12	62	50	-179	37	82	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	24	1	22222	\N	11	2.7999999999999998	01.10.2000	04:48	62	23.800000000000001	-179	47.600000000000001	133	01.10.2000	04:48	62	22.300000000000001	-179	53	140	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	53	1	22222	\N	11	2.6000000000000001	07.10.2000	06:00	63	0.90000000000000002	-178	8.0999999999999996	93	07.10.2000	06:00	63	3.1000000000000001	-178	10.1	93	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	54	1	22222	\N	11	2.7999999999999998	07.10.2000	04:48	63	27.899999999999999	-178	29.199999999999999	81	07.10.2000	04:48	63	25	-178	32.799999999999997	81	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	55	1	22222	\N	11	2.6000000000000001	08.10.2000	12:00	63	7.0999999999999996	-179	4.5	81	08.10.2000	12:00	63	4.7000000000000002	-179	7.0999999999999996	83	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	56	1	22222	\N	11	2.6000000000000001	08.10.2000	12:00	61	57.799999999999997	179	50.799999999999997	122	08.10.2000	12:00	61	58.799999999999997	179	52.399999999999999	125	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	25	1	22222	\N	11	2.6000000000000001	01.10.2000	04:48	62	2.3999999999999999	178	6.5	81	01.10.2000	04:48	62	0.29999999999999999	178	10.9	86	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	26	1	22222	\N	11	2.5	02.10.2000	02:24	61	45.600000000000001	178	36.700000000000003	130	02.10.2000	02:24	61	45.399999999999999	178	40.899999999999999	122	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	27	1	22222	\N	11	2.5	02.10.2000	00:00	61	39	178	42	147	02.10.2000	00:00	61	41.5	178	41.899999999999999	144	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	28	1	22222	\N	11	2.2999999999999998	03.10.2000	03:36	61	39.799999999999997	179	43.200000000000003	155	03.10.2000	03:36	61	38.100000000000001	179	37.600000000000001	144	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	29	1	22222	\N	11	2.5	03.10.2000	00:00	61	56.5	179	30.699999999999999	116	03.10.2000	00:00	61	57.899999999999999	179	35.200000000000003	121	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	30	1	22222	\N	11	3	03.10.2000	00:00	63	8.4000000000000004	-179	40	66	03.10.2000	00:00	63	11	-179	39	63	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	31	1	22222	\N	11	2.5	04.10.2000	09:36	63	35.100000000000001	-179	56.700000000000003	47	04.10.2000	09:36	63	37.700000000000003	-179	55.5	49	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	32	1	22222	\N	11	2.5	04.10.2000	04:48	63	57.799999999999997	-179	50.200000000000003	45	04.10.2000	04:48	64	0.29999999999999999	-179	51.100000000000001	45	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	35	1	22222	\N	11	2.5	04.10.2000	02:24	64	24.5	-177	17.800000000000001	71	04.10.2000	02:24	64	23.100000000000001	-177	15	70	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	36	1	22222	\N	11	3	04.10.2000	10:48	64	37.399999999999999	-176	22.199999999999999	71	04.10.2000	07:12	64	37.899999999999999	-176	18.899999999999999	70	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	37	1	22222	\N	11	2.6000000000000001	05.10.2000	00:00	64	21.300000000000001	-175	18.5	73	05.10.2000	00:00	64	17.699999999999999	-175	6.4000000000000004	76	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	38	1	22222	\N	11	2.7999999999999998	05.10.2000	07:12	64	0	-174	22	73	05.10.2000	07:12	63	59	-174	22.300000000000001	73	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	39	1	22222	\N	11	2.6000000000000001	05.10.2000	02:24	63	38.899999999999999	-174	30	78	05.10.2000	02:24	63	39.700000000000003	-174	36.799999999999997	79	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	40	1	22222	\N	11	2.6000000000000001	05.10.2000	13:12	63	48.700000000000003	-175	31.899999999999999	79	05.10.2000	13:12	63	50.5	-175	37	80	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	41	1	22222	\N	11	3	05.10.2000	00:00	64	4	-176	25	81	05.10.2000	12:00	64	5	-176	28.699999999999999	81	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	42	1	22222	\N	11	2.6000000000000001	06.10.2000	02:24	63	53.299999999999997	-177	31.5	82	06.10.2000	02:24	63	53.100000000000001	-177	39.5	83	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	45	1	22222	\N	11	2.7999999999999998	06.10.2000	09:36	63	39.299999999999997	-177	49.899999999999999	85	06.10.2000	09:36	63	39.299999999999997	-177	44.100000000000001	87	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	46	1	22222	\N	11	2.6000000000000001	06.10.2000	00:00	63	34.5	-176	38.399999999999999	85	06.10.2000	00:00	63	33.299999999999997	-176	32.899999999999999	84	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	47	1	22222	\N	11	2.5	06.10.2000	09:36	63	23.899999999999999	-175	41.600000000000001	81	06.10.2000	09:36	63	21.800000000000001	-175	38.5	80	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	48	1	22222	\N	11	2.7999999999999998	06.10.2000	12:00	63	6	-175	20	80	06.10.2000	12:00	63	3	-175	23	79	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	49	1	22222	\N	11	2.6000000000000001	07.10.2000	06:00	62	43.5	-175	45.799999999999997	80	07.10.2000	06:00	62	45.799999999999997	-175	48.700000000000003	80	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	50	1	22222	\N	11	2.6000000000000001	07.10.2000	07:12	63	3.2999999999999998	-176	9.3000000000000007	83	07.10.2000	07:12	63	2	-176	13.800000000000001	84	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	51	1	22222	\N	11	2.8999999999999999	07.10.2000	08:24	62	48	-176	58.799999999999997	90	07.10.2000	08:24	62	51.200000000000003	-177	0	90	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	52	1	22222	\N	11	2.6000000000000001	07.10.2000	06:00	63	15.199999999999999	-177	10.6	87	07.10.2000	06:00	63	13.199999999999999	-177	15.9	90	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	53	1	22222	\N	11	2.6000000000000001	07.10.2000	06:00	63	0.90000000000000002	-178	8.0999999999999996	93	07.10.2000	06:00	63	3.1000000000000001	-178	10.1	93	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	54	1	22222	\N	11	2.7999999999999998	07.10.2000	04:48	63	27.899999999999999	-178	29.199999999999999	81	07.10.2000	04:48	63	25	-178	32.799999999999997	81	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	55	1	22222	\N	11	2.6000000000000001	08.10.2000	12:00	63	7.0999999999999996	-179	4.5	81	08.10.2000	12:00	63	4.7000000000000002	-179	7.0999999999999996	83	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	1	56	1	22222	\N	11	2.6000000000000001	08.10.2000	12:00	61	57.799999999999997	179	50.799999999999997	122	08.10.2000	12:00	61	58.799999999999997	179	52.399999999999999	125	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	12	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	15	1	22222	\N	11	2.6000000000000001	29.09.2000	04:48	62	10.1	-177	49.700000000000003	108	29.09.2000	04:48	62	8	-177	45.600000000000001	109	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	16	1	22222	\N	11	2.5	29.09.2000	06:00	62	6.4000000000000004	-176	47.799999999999997	99	29.09.2000	06:00	62	4.7000000000000002	-176	50.399999999999999	101	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	17	1	22222	\N	11	2.5	29.09.2000	04:48	61	54	-177	9	112	29.09.2000	04:48	61	52.200000000000003	-177	14	114	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	18	1	22222	\N	11	2.6000000000000001	29.09.2000	04:48	61	49	-177	16	130	29.09.2000	04:48	61	51.5	-177	13.199999999999999	122	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	19	1	22222	\N	11	2.5	30.09.2000	02:24	61	34.600000000000001	-178	0.40000000000000002	143	30.09.2000	02:24	61	32.200000000000003	-178	1.8	148	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	20	1	22222	\N	11	2.5	30.09.2000	12:00	62	4	-178	14	113	30.09.2000	12:00	62	6.5	-178	14.4	111	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	21	1	22222	\N	11	2.6000000000000001	30.09.2000	06:00	62	37.799999999999997	-178	6.9000000000000004	94	30.09.2000	06:00	62	38.5	-178	12	94	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	22	1	22222	\N	11	2.5	30.09.2000	09:36	62	44.5	-178	53.799999999999997	92	30.09.2000	09:36	62	45.399999999999999	-178	59.899999999999999	92	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	23	1	22222	\N	11	2.5	30.09.2000	07:12	62	48.799999999999997	-179	34.899999999999999	86	30.09.2000	07:12	62	50	-179	37	82	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	24	1	22222	\N	11	2.7999999999999998	01.10.2000	04:48	62	23.800000000000001	-179	47.600000000000001	133	01.10.2000	04:48	62	22.300000000000001	-179	53	140	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	25	1	22222	\N	11	2.6000000000000001	01.10.2000	04:48	62	2.3999999999999999	178	6.5	81	01.10.2000	04:48	62	0.29999999999999999	178	10.9	86	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	26	1	22222	\N	11	2.5	02.10.2000	02:24	61	45.600000000000001	178	36.700000000000003	130	02.10.2000	02:24	61	45.399999999999999	178	40.899999999999999	122	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	27	1	22222	\N	11	2.5	02.10.2000	00:00	61	39	178	42	147	02.10.2000	00:00	61	41.5	178	41.899999999999999	144	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	28	1	22222	\N	11	2.2999999999999998	03.10.2000	03:36	61	39.799999999999997	179	43.200000000000003	155	03.10.2000	03:36	61	38.100000000000001	179	37.600000000000001	144	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	29	1	22222	\N	11	2.5	03.10.2000	00:00	61	56.5	179	30.699999999999999	116	03.10.2000	00:00	61	57.899999999999999	179	35.200000000000003	121	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	30	1	22222	\N	11	3	03.10.2000	00:00	63	8.4000000000000004	-179	40	66	03.10.2000	00:00	63	11	-179	39	63	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	31	1	22222	\N	11	2.5	04.10.2000	09:36	63	35.100000000000001	-179	56.700000000000003	47	04.10.2000	09:36	63	37.700000000000003	-179	55.5	49	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	32	1	22222	\N	11	2.5	04.10.2000	04:48	63	57.799999999999997	-179	50.200000000000003	45	04.10.2000	04:48	64	0.29999999999999999	-179	51.100000000000001	45	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	33	1	22222	\N	11	3	04.10.2000	00:00	64	15.800000000000001	-179	56	46	04.10.2000	09:36	64	16	-179	53	46	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	34	1	22222	\N	11	2.7999999999999998	04.10.2000	03:36	64	54.399999999999999	-177	46.100000000000001	60	04.10.2000	03:36	64	51.899999999999999	-177	42	60	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	35	1	22222	\N	11	2.5	04.10.2000	02:24	64	24.5	-177	17.800000000000001	71	04.10.2000	02:24	64	23.100000000000001	-177	15	70	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	36	1	22222	\N	11	3	04.10.2000	10:48	64	37.399999999999999	-176	22.199999999999999	71	04.10.2000	07:12	64	37.899999999999999	-176	18.899999999999999	70	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	37	1	22222	\N	11	2.6000000000000001	05.10.2000	00:00	64	21.300000000000001	-175	18.5	73	05.10.2000	00:00	64	17.699999999999999	-175	6.4000000000000004	76	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	38	1	22222	\N	11	2.7999999999999998	05.10.2000	07:12	64	0	-174	22	73	05.10.2000	07:12	63	59	-174	22.300000000000001	73	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	39	1	22222	\N	11	2.6000000000000001	05.10.2000	02:24	63	38.899999999999999	-174	30	78	05.10.2000	02:24	63	39.700000000000003	-174	36.799999999999997	79	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	40	1	22222	\N	11	2.6000000000000001	05.10.2000	13:12	63	48.700000000000003	-175	31.899999999999999	79	05.10.2000	13:12	63	50.5	-175	37	80	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	42	1	22222	\N	11	2.6000000000000001	06.10.2000	02:24	63	53.299999999999997	-177	31.5	82	06.10.2000	02:24	63	53.100000000000001	-177	39.5	83	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	45	1	22222	\N	11	2.7999999999999998	06.10.2000	09:36	63	39.299999999999997	-177	49.899999999999999	85	06.10.2000	09:36	63	39.299999999999997	-177	44.100000000000001	87	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	46	1	22222	\N	11	2.6000000000000001	06.10.2000	00:00	63	34.5	-176	38.399999999999999	85	06.10.2000	00:00	63	33.299999999999997	-176	32.899999999999999	84	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
2000	000а	2	47	1	22222	\N	11	2.5	06.10.2000	09:36	63	23.899999999999999	-175	41.600000000000001	81	06.10.2000	09:36	63	21.800000000000001	-175	38.5	80	22222	22222	\N	0	22222	22222	22222	22222	22222	22222	22222	22222	1	123	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: vessel_spr; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY vessel_spr (vesselcode, name, class, port, numbreg, hullno, callsign, myear, shipowner, mlength, maxlength, midshipht, freeboard, middraft, grt, nrt, dedweit, cargospace, numbtanks, engpower, enginetype, cruisspeed, decwinch, winchpower, crew, namecapt) FROM stdin;
000а	"Капитан Селюк"	РК МРТ		22222		000а	22222		22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222		22222		22222	22222	Масловский Владимир Петрович
AART	Максим Старостин			0		AART	0	5555555555555555555	0	0	0	0	0	0	0	0	0	0	0		0		0	0	
UAZN	Капитан Рогозин			22222		UAZN	0	444444444444444444	0	0	0	0	0	0	0	0	0	0	0		0		0	0	
0001	Сафил			22222		0001	22222		22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222		22222		22222	22222	Осадчий Валентин Павлович
QQQQ	qqqqq			22222		QQQQ	22222		22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222		22222		22222	22222	
1234	Проф. Кизеветтер			22222		1234	22222		22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222		22222		22222	22222	
UHGK	Сарычевск			22222		UHGK	22222		22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222		22222		22222	22222	
УАХФ	М-0520 "Профессор Бойко"	КМ А Л3А	Мурманск	941174	9282340	УАХФ	22222	ФГУП "ПИНРО"	29.600000000000001	32.100000000000001	6.0999999999999996	22222	22222	22222	22222	22222	22222	22222	22222		22222		22222	23	Коваль-Волков Александр Алек
1122	Глобино	РС		22222		1122	22222		22222	22222	22222	22222	22222	22222	22222	22222	22222	22222	22222		22222		22222	22222	Вишня Н.В.
\.


--
-- Name: bioanalis_krill_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bioanalis_krill
    ADD CONSTRAINT bioanalis_krill_pkey PRIMARY KEY (myear, vesselcode, numsurvey, numstn, speciescode, numspec);


--
-- Name: pk_promer; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY promer
    ADD CONSTRAINT pk_promer PRIMARY KEY (myear, vesselcode, numsurvey, numstn, speciescode, sex, sizeclass);


--
-- Name: pk_species_spr_1; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY species_spr
    ADD CONSTRAINT pk_species_spr_1 PRIMARY KEY (speciescode);


--
-- Name: pr_bioanalis_crab; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bioanalis_crab
    ADD CONSTRAINT pr_bioanalis_crab PRIMARY KEY (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec);


--
-- Name: pr_bioanalis_craboid; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bioanalis_craboid
    ADD CONSTRAINT pr_bioanalis_craboid PRIMARY KEY (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec);


--
-- Name: pr_bioanalis_echinoidea; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bioanalis_echinoidea
    ADD CONSTRAINT pr_bioanalis_echinoidea PRIMARY KEY (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec);


--
-- Name: pr_bioanalis_golotur; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bioanalis_golotur
    ADD CONSTRAINT pr_bioanalis_golotur PRIMARY KEY (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec);


--
-- Name: pr_bioanalis_krevet; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bioanalis_krevet
    ADD CONSTRAINT pr_bioanalis_krevet PRIMARY KEY (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec);


--
-- Name: pr_bioanalis_molusk; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bioanalis_molusk
    ADD CONSTRAINT pr_bioanalis_molusk PRIMARY KEY (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec);


--
-- Name: pr_bioanalis_pelecipoda; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bioanalis_pelecipoda
    ADD CONSTRAINT pr_bioanalis_pelecipoda PRIMARY KEY (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec);


--
-- Name: pr_bioanalis_squid; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY bioanalis_squid
    ADD CONSTRAINT pr_bioanalis_squid PRIMARY KEY (myear, vesselcode, numsurvey, numstn, numstrat, speciescode, numspec);


--
-- Name: pr_catch; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY catch
    ADD CONSTRAINT pr_catch PRIMARY KEY (myear, vesselcode, numsurvey, numstn, grup, speciescode);


--
-- Name: pr_gear_spr; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY gear_spr
    ADD CONSTRAINT pr_gear_spr PRIMARY KEY (gearcode);


--
-- Name: pr_grunt_spr; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY grunt_spr
    ADD CONSTRAINT pr_grunt_spr PRIMARY KEY (bottomcode);


--
-- Name: pr_illness_spr; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY illness_spr
    ADD CONSTRAINT pr_illness_spr PRIMARY KEY (illnesscode);


--
-- Name: pr_jurnalcatchstrat; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY jurnalcatchstrat
    ADD CONSTRAINT pr_jurnalcatchstrat PRIMARY KEY (myear, vesselcode, numsurvey, numstn, numstrat, speciescode);


--
-- Name: pr_jurnalstrat; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY jurnalstrat
    ADD CONSTRAINT pr_jurnalstrat PRIMARY KEY (myear, vesselcode, numsurvey, numstn, numstrat);


--
-- Name: pr_observ_spr; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY observ_spr
    ADD CONSTRAINT pr_observ_spr PRIMARY KEY (observcode);


--
-- Name: pr_stations; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY stations
    ADD CONSTRAINT pr_stations PRIMARY KEY (myear, vesselcode, numsurvey, numstn, typesurvey);


--
-- Name: pr_vessel_spr; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY vessel_spr
    ADD CONSTRAINT pr_vessel_spr PRIMARY KEY (vesselcode);


--
-- Name: bioanalis_crab_illnesscode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_crab
    ADD CONSTRAINT bioanalis_crab_illnesscode_fkey FOREIGN KEY (illnesscode) REFERENCES illness_spr(illnesscode);


--
-- Name: bioanalis_crab_observcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_crab
    ADD CONSTRAINT bioanalis_crab_observcode_fkey FOREIGN KEY (observcode) REFERENCES observ_spr(observcode);


--
-- Name: bioanalis_crab_speciescode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_crab
    ADD CONSTRAINT bioanalis_crab_speciescode_fkey FOREIGN KEY (speciescode) REFERENCES species_spr(speciescode);


--
-- Name: bioanalis_crab_vesselcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_crab
    ADD CONSTRAINT bioanalis_crab_vesselcode_fkey FOREIGN KEY (vesselcode) REFERENCES vessel_spr(vesselcode);


--
-- Name: bioanalis_craboid_illnesscode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_craboid
    ADD CONSTRAINT bioanalis_craboid_illnesscode_fkey FOREIGN KEY (illnesscode) REFERENCES illness_spr(illnesscode);


--
-- Name: bioanalis_craboid_observcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_craboid
    ADD CONSTRAINT bioanalis_craboid_observcode_fkey FOREIGN KEY (observcode) REFERENCES observ_spr(observcode);


--
-- Name: bioanalis_craboid_speciescode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_craboid
    ADD CONSTRAINT bioanalis_craboid_speciescode_fkey FOREIGN KEY (speciescode) REFERENCES species_spr(speciescode);


--
-- Name: bioanalis_craboid_vesselcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_craboid
    ADD CONSTRAINT bioanalis_craboid_vesselcode_fkey FOREIGN KEY (vesselcode) REFERENCES vessel_spr(vesselcode);


--
-- Name: bioanalis_echinoidea_observcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_echinoidea
    ADD CONSTRAINT bioanalis_echinoidea_observcode_fkey FOREIGN KEY (observcode) REFERENCES observ_spr(observcode);


--
-- Name: bioanalis_echinoidea_speciescode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_echinoidea
    ADD CONSTRAINT bioanalis_echinoidea_speciescode_fkey FOREIGN KEY (speciescode) REFERENCES species_spr(speciescode);


--
-- Name: bioanalis_echinoidea_vesselcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_echinoidea
    ADD CONSTRAINT bioanalis_echinoidea_vesselcode_fkey FOREIGN KEY (vesselcode) REFERENCES vessel_spr(vesselcode);


--
-- Name: bioanalis_golotur_observcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_golotur
    ADD CONSTRAINT bioanalis_golotur_observcode_fkey FOREIGN KEY (observcode) REFERENCES observ_spr(observcode);


--
-- Name: bioanalis_golotur_speciescode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_golotur
    ADD CONSTRAINT bioanalis_golotur_speciescode_fkey FOREIGN KEY (speciescode) REFERENCES species_spr(speciescode);


--
-- Name: bioanalis_golotur_vesselcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_golotur
    ADD CONSTRAINT bioanalis_golotur_vesselcode_fkey FOREIGN KEY (vesselcode) REFERENCES vessel_spr(vesselcode);


--
-- Name: bioanalis_krevet_illnesscode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_krevet
    ADD CONSTRAINT bioanalis_krevet_illnesscode_fkey FOREIGN KEY (illnesscode) REFERENCES illness_spr(illnesscode);


--
-- Name: bioanalis_krevet_observcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_krevet
    ADD CONSTRAINT bioanalis_krevet_observcode_fkey FOREIGN KEY (observcode) REFERENCES observ_spr(observcode);


--
-- Name: bioanalis_krevet_speciescode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_krevet
    ADD CONSTRAINT bioanalis_krevet_speciescode_fkey FOREIGN KEY (speciescode) REFERENCES species_spr(speciescode);


--
-- Name: bioanalis_krevet_vesselcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_krevet
    ADD CONSTRAINT bioanalis_krevet_vesselcode_fkey FOREIGN KEY (vesselcode) REFERENCES vessel_spr(vesselcode);


--
-- Name: bioanalis_krill_illnesscode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_krill
    ADD CONSTRAINT bioanalis_krill_illnesscode_fkey FOREIGN KEY (illnesscode) REFERENCES illness_spr(illnesscode);


--
-- Name: bioanalis_krill_observcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_krill
    ADD CONSTRAINT bioanalis_krill_observcode_fkey FOREIGN KEY (observcode) REFERENCES observ_spr(observcode);


--
-- Name: bioanalis_krill_speciescode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_krill
    ADD CONSTRAINT bioanalis_krill_speciescode_fkey FOREIGN KEY (speciescode) REFERENCES species_spr(speciescode);


--
-- Name: bioanalis_krill_vesselcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_krill
    ADD CONSTRAINT bioanalis_krill_vesselcode_fkey FOREIGN KEY (vesselcode) REFERENCES vessel_spr(vesselcode);


--
-- Name: bioanalis_molusk_observcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_molusk
    ADD CONSTRAINT bioanalis_molusk_observcode_fkey FOREIGN KEY (observcode) REFERENCES observ_spr(observcode);


--
-- Name: bioanalis_molusk_speciescode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_molusk
    ADD CONSTRAINT bioanalis_molusk_speciescode_fkey FOREIGN KEY (speciescode) REFERENCES species_spr(speciescode);


--
-- Name: bioanalis_molusk_vesselcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_molusk
    ADD CONSTRAINT bioanalis_molusk_vesselcode_fkey FOREIGN KEY (vesselcode) REFERENCES vessel_spr(vesselcode);


--
-- Name: bioanalis_pelecipoda_illnesscode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_pelecipoda
    ADD CONSTRAINT bioanalis_pelecipoda_illnesscode_fkey FOREIGN KEY (illnesscode) REFERENCES illness_spr(illnesscode);


--
-- Name: bioanalis_pelecipoda_observcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_pelecipoda
    ADD CONSTRAINT bioanalis_pelecipoda_observcode_fkey FOREIGN KEY (observcode) REFERENCES observ_spr(observcode);


--
-- Name: bioanalis_pelecipoda_speciescode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_pelecipoda
    ADD CONSTRAINT bioanalis_pelecipoda_speciescode_fkey FOREIGN KEY (speciescode) REFERENCES species_spr(speciescode);


--
-- Name: bioanalis_pelecipoda_vesselcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_pelecipoda
    ADD CONSTRAINT bioanalis_pelecipoda_vesselcode_fkey FOREIGN KEY (vesselcode) REFERENCES vessel_spr(vesselcode);


--
-- Name: bioanalis_squid_observcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_squid
    ADD CONSTRAINT bioanalis_squid_observcode_fkey FOREIGN KEY (observcode) REFERENCES observ_spr(observcode);


--
-- Name: bioanalis_squid_speciescode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_squid
    ADD CONSTRAINT bioanalis_squid_speciescode_fkey FOREIGN KEY (speciescode) REFERENCES species_spr(speciescode);


--
-- Name: bioanalis_squid_vesselcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY bioanalis_squid
    ADD CONSTRAINT bioanalis_squid_vesselcode_fkey FOREIGN KEY (vesselcode) REFERENCES vessel_spr(vesselcode);


--
-- Name: catch_observcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY catch
    ADD CONSTRAINT catch_observcode_fkey FOREIGN KEY (observcode) REFERENCES observ_spr(observcode);


--
-- Name: catch_speciescode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY catch
    ADD CONSTRAINT catch_speciescode_fkey FOREIGN KEY (speciescode) REFERENCES species_spr(speciescode);


--
-- Name: catch_vesselcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY catch
    ADD CONSTRAINT catch_vesselcode_fkey FOREIGN KEY (vesselcode) REFERENCES vessel_spr(vesselcode);


--
-- Name: stations_bottomcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stations
    ADD CONSTRAINT stations_bottomcode_fkey FOREIGN KEY (bottomcode) REFERENCES grunt_spr(bottomcode);


--
-- Name: stations_gearcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stations
    ADD CONSTRAINT stations_gearcode_fkey FOREIGN KEY (gearcode) REFERENCES gear_spr(gearcode);


--
-- Name: stations_observcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stations
    ADD CONSTRAINT stations_observcode_fkey FOREIGN KEY (observcode) REFERENCES observ_spr(observcode);


--
-- Name: vessel_key; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY stations
    ADD CONSTRAINT vessel_key FOREIGN KEY (vesselcode) REFERENCES vessel_spr(vesselcode);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: observ_spr; Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON TABLE observ_spr FROM PUBLIC;
REVOKE ALL ON TABLE observ_spr FROM postgres;
GRANT ALL ON TABLE observ_spr TO plkv;


--
-- PostgreSQL database dump complete
--

