create or replace package pkg_wrap as

  -- This procedure creates a new wrapped object
  procedure prc_wrap_new(p_src in clob);

  -- This procedure overwrites an existing object, wrapping it *BE CAREFUL*
  procedure prc_wrap(p_name in varchar2);

  -- This procedure overwrites an existing object, unwrapping it *BE CAREFUL*
  procedure prc_unwrap(p_name  in varchar2);

  -- This function returns the source of a wrapped object
  function  fnc_unwrap(p_name  in varchar2
                      ,p_owner in varchar2 default user) return clob;
end;
/

create or replace package body pkg_wrap as

function clob_concat(p_clob in clob, p_clob2 in clob) return clob is
  v_clob   clob;
  v_return clob := empty_clob();
begin
  if (nvl(dbms_lob.getlength(p_clob2),0) = 0 ) then
    return null;
  end if;
  dbms_lob.createtemporary(v_clob,true);
  dbms_lob.append(v_clob,p_clob);
  dbms_lob.append(v_clob,p_clob2);
  v_return := v_clob;
  dbms_lob.freetemporary(v_clob);
  return v_return;
end clob_concat;

procedure prc_wrap_new(p_src in clob) is
  v_i   number := 0;
  v_src dbms_sql.varchar2a;
begin
  for i in 1 .. (ceil(nvl(dbms_lob.getlength(p_src),0)/32767)) loop
    v_i := v_i + 1;
    v_src(v_i) := dbms_lob.substr(p_src,32767,v_i*32767-32767 + 1);
  end loop;
  htp.p(v_src(1));
  dbms_ddl.create_wrapped(v_src,1,v_i);
end prc_wrap_new;

procedure prc_unwrap(p_name in varchar2) is 
  v_cursor pls_integer;
  v_rows   pls_integer;
begin
  v_cursor := dbms_sql.open_cursor;
  dbms_sql.parse(c             => v_cursor
                ,statement     => 'create or replace '||fnc_unwrap(p_name)
                ,language_flag => dbms_sql.native);
  v_rows := dbms_sql.execute(v_cursor);
  dbms_sql.close_cursor(v_cursor);
end prc_unwrap;

procedure prc_wrap(p_name in varchar2) is
  v_src clob := empty_clob();
  cursor obj is
    select object_name name
          ,object_type type
      from user_objects
     where object_name = upper(p_name)
       and object_type in ('PROCEDURE','PACKAGE BODY','FUNCTION','TYPE BODY')
     order by object_type;

  cursor src(pp_name in varchar2
            ,pp_type in varchar2) is
    select text
      from user_source
     where name = upper(pp_name)
       and type   = upper(pp_type)
     order by line;

begin
  for o in obj loop
    v_src := empty_clob();
    for s in src(o.name, o.type) loop
      v_src := clob_concat(v_src, to_clob(s.text));
    end loop;
    v_src := 'create or replace ' || v_src;
    dbms_ddl.create_wrapped(v_src);
  end loop;
end prc_wrap;

function fnc_unwrap(p_name  in varchar2
                   ,p_owner in varchar2 default user) return clob as

  charmap_original constant varchar2(512) := '000102030405060708090A0B0C0D0E0F' ||
                                             '101112131415161718191A1B1C1D1E1F' ||
                                             '202122232425262728292A2B2C2D2E2F' ||
                                             '303132333435363738393A3B3C3D3E3F' ||
                                             '404142434445464748494A4B4C4D4E4F' ||
                                             '505152535455565758595A5B5C5D5E5F' ||
                                             '606162636465666768696A6B6C6D6E6F' ||
                                             '707172737475767778797A7B7C7D7E7F' ||
                                             '808182838485868788898A8B8C8D8E8F' ||
                                             '909192939495969798999A9B9C9D9E9F' ||
                                             'A0A1A2A3A4A5A6A7A8A9AAABACADAEAF' ||
                                             'B0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF' ||
                                             'C0C1C2C3C4C5C6C7C8C9CACBCCCDCECF' ||
                                             'D0D1D2D3D4D5D6D7D8D9DADBDCDDDEDF' ||
                                             'E0E1E2E3E4E5E6E7E8E9EAEBECEDEEEF' ||
                                             'F0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF';

  charmap_replaced constant varchar2(512) := '3D6585B318DBE287F152AB634BB5A05F' ||
                                             '7D687B9B24C228678ADEA4261E03EB17' ||
                                             '6F343E7A3FD2A96A0FE935561FB14D10' ||
                                             '78D975F6BC4104816106F9ADD6D5297E' ||
                                             '869E79E505BA84CC6E278EB05DA8F39F' ||
                                             'D0A271B858DD2C38994C480755E4538C' ||
                                             '46B62DA5AF322240DC50C3A1258B9C16' ||
                                             '605CCFFD0C981CD4376D3C3A30E86C31' ||
                                             '47F533DA43C8E35E1994ECE6A39514E0' ||
                                             '9D64FA5915C52FCABB0BDFF297BF0A76' ||
                                             'B449445A1DF0009621807F1A82394FC1' ||
                                             'A7D70DD1D8FF139370EE5BEFBE09B977' ||
                                             '72E7B254B72AC7739066200E51EDF87C' ||
                                             '8F2EF412C62B83CDACCB3BC44EC06936' ||
                                             '6202AE88FCAA4208A64557D39ABDE123' ||
                                             '8D924A1189746B91FBFEC901EA1BF7CE' ;

  cursor obj is
    select object_name name
          ,object_type type
          ,owner     owner
      from all_objects
     where object_name  = upper(p_name)
       and owner        = upper(p_owner)
       and object_name != 'PKG_WRAP'
       and object_type in ('PROCEDURE','PACKAGE BODY','FUNCTION','TYPE BODY')
     order by object_type;

  cursor src(pp_name in varchar2, pp_type in varchar2, pp_owner in varchar2) is
    select case when (line = 1) then 
             substr( text, instr( text, chr( 10 ), 1, 20 ) + 1 ) 
           else 
             text 
           end text
      from all_source
     where name  = upper(pp_name)
       and type  = upper(pp_type)
       and owner = upper(pp_owner)
     order by line;

  v_src   clob := empty_clob();
  v_dummy varchar2(4000);

  FUNCTION blob2clob(plob IN BLOB) RETURN CLOB IS
    lclob_Result   CLOB    := 'X';
    l_dest_offsset INTEGER := 1;
    l_src_offsset  INTEGER := 1;
    l_lang_context INTEGER := dbms_lob.default_lang_ctx;
    l_warning      INTEGER;
  BEGIN
    IF plob IS NOT NULL AND LENGTH(plob) > 0 THEN
      dbms_lob.converttoclob(dest_lob   => lclob_Result
                            ,src_blob   => plob
                            ,amount     => dbms_lob.lobmaxsize
                            ,dest_offset  => l_dest_offsset
                            ,src_offset   => l_src_offsset
                            ,blob_csid  => dbms_lob.default_csid
                            ,lang_context => l_lang_context
                            ,warning    => l_warning);
      IF l_warning != 0 THEN
        dbms_output.put_line('Function blob_to_clob warning:' || l_warning);
        RETURN NULL;
      END IF;
      RETURN(lclob_Result);
    ELSE
      RETURN NULL;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('Function blob_to_clob error:' || SQLCODE);
      RETURN NULL;
  END;

  function base64_decode(p_clob in clob) return clob is
    v_result         clob           := empty_clob();
    v_clob           clob           := empty_clob();
    v_offset         integer        := 1;
    v_buffer_size    binary_integer := 112;
    v_buffer_varchar varchar2(224);
  begin
    if (p_clob is null) then
      return null;
    end if;
    dbms_lob.createtemporary(v_clob, true);
    for i in 1..ceil(nvl(dbms_lob.getlength(p_clob),0) / v_buffer_size) loop
      dbms_lob.read(p_clob, v_buffer_size, v_offset, v_buffer_varchar);
      v_buffer_varchar := utl_encode.base64_decode(hextoraw(v_buffer_varchar));
      dbms_lob.writeappend(v_clob, length(v_buffer_varchar), v_buffer_varchar);
      v_offset := v_offset + v_buffer_size;
    end loop;
    v_result := v_clob;
    dbms_lob.freetemporary(v_clob);
    return v_result;
  end;

  function clob_translate(p_clob in clob) return clob is
    -- must receive a clob already converted to raw format
    v_result         clob           := empty_clob();
    v_clob           clob           := empty_clob();
    v_offset         integer        := 1;
    v_buffer_size    binary_integer := 2000;
    v_buffer_varchar varchar2(2000);
  begin
    if (p_clob is null) then
      return null;
    end if;
    dbms_lob.createtemporary(v_clob, true);
    for i in 1..ceil(dbms_lob.getlength(p_clob) / v_buffer_size) loop
      dbms_lob.read(p_clob, v_buffer_size, v_offset, v_buffer_varchar);
      v_buffer_varchar := utl_raw.translate(v_buffer_varchar,charmap_original,charmap_replaced);
      dbms_lob.writeappend(v_clob, length(v_buffer_varchar), v_buffer_varchar);
      v_offset := v_offset + v_buffer_size;
    end loop;
    v_result := v_clob;
    dbms_lob.freetemporary(v_clob);
    return v_result;
  end;

  function decodeZLIB( p_src in blob ) return blob is
    t_out       blob;
    t_tmp       blob;
    t_buf       raw(8132);
    t_buffer    raw(1);
    t_hdl       binary_integer;
    t_max_loops pls_integer;
    t_s1        pls_integer; -- s1 part of adler32 checksum
    t_last_chr  pls_integer;
  begin
    dbms_lob.createtemporary( t_out, true );
    dbms_lob.createtemporary( t_tmp, true );
    t_tmp := hextoraw( '1F8B0800000000000003' ); -- gzip header
    dbms_lob.copy( t_tmp, p_src, dbms_lob.getlength( p_src ) -  2 - 4, 11, 3 );
    dbms_lob.append( t_tmp, hextoraw( '0000000000000000' ) ); -- add a fake trailer
    t_hdl := utl_compress.lz_uncompress_open( t_tmp );
    t_s1 := 1;
    t_max_loops := 0;
    loop
      begin
        utl_compress.lz_uncompress_extract( t_hdl, t_buf );
        dbms_lob.append( t_out, t_buf );
        for i in 1 .. 8132 loop
          t_s1 := mod( t_s1 + utl_raw.cast_to_binary_integer( utl_raw.substr( t_buf, i, 1 ) ), 65521 );
        end loop;
        t_max_loops := t_max_loops + 1;
      exception when others then
        if utl_compress.isopen( t_hdl ) then
          utl_compress.lz_uncompress_close( t_hdl );
        end if;
        t_hdl := utl_compress.lz_uncompress_open( t_tmp );
        exit;
      end;
    end loop;
    for i in 1 .. t_max_loops loop
      utl_compress.lz_uncompress_extract( t_hdl, t_buf );
    end loop;
    loop
      begin
        utl_compress.lz_uncompress_extract( t_hdl, t_buffer );
      exception when others then
        exit;
      end;
      dbms_lob.append( t_out, t_buffer );
      t_s1 := mod( t_s1 + to_number( rawtohex( t_buffer ), 'xx' ), 65521 );
    end loop;
    t_last_chr := to_number( dbms_lob.substr( p_src, 2, dbms_lob.getlength( p_src ) - 1 ), '0XXX') - t_s1;
    if t_last_chr < 0 then
      t_last_chr := t_last_chr + 65521;
    end if;
    dbms_output.put_line( t_s1 || 'x' || t_last_chr );
    dbms_lob.append( t_out, hextoraw( to_char( t_last_chr, 'fm0XXX' ) ) );
    if utl_compress.isopen( t_hdl ) then
      utl_compress.lz_uncompress_close( t_hdl );
    end if;
    dbms_lob.freetemporary( t_tmp );
    return t_out;
  end decodeZLIB;

  function copy2blob(p_clob in clob) return blob is
    v_return   blob   := empty_blob();
    v_amout    number := 2000;
    v_offset   number := 1;
    v_clob_len number := nvl(dbms_lob.getlength(p_clob),0);
    v_blob     blob;
    v_buffer   raw(2000);
  begin
    if (v_clob_len = 0) then
      return null;
    end if;
    dbms_lob.createtemporary(v_blob,true);
    for i in 1..ceil(v_clob_len/v_amout) loop
      dbms_lob.read(p_clob, v_amout, v_offset, v_buffer);
      dbms_lob.writeappend(v_blob, utl_raw.length(v_buffer), v_buffer);
      v_offset := v_offset + v_amout;
    end loop;
    v_return := v_blob;
    dbms_lob.freetemporary(v_blob);
    return v_return;
  end copy2blob;

BEGIN
  for o in obj loop
    for s in src(o.name, o.type, o.owner) loop
      v_dummy := replace(s.text,chr(10));
      if (regexp_count(v_dummy,'[^[:alnum:]*|(\+)*|(\/)*|(\=)*]') > 0) then -- Verify if it is a based64 text
        return 'The source is not protected';
      else
        v_src := clob_concat(v_src, to_clob(utl_raw.cast_to_raw(v_dummy)));
      end if;
    end loop;
  end loop;
  if (nvl(dbms_lob.getlength(v_src),0) > 0) then
    v_src := base64_decode(v_src); -- Decode base64
    v_src := regexp_substr(v_src,'.*',41,1,'n'); -- Get from 21th char
    v_src := clob_translate(v_src); -- Replace Charmap *HACK*
    v_src := blob2clob(decodeZLIB(copy2blob(v_src))); -- Uncompress using ZLIB
    v_src := regexp_replace(v_src, '[^[:graph:]]+', '',dbms_lob.getlength(v_src)-1,1); -- Bug Fix CHR(0)
  else
    return 'Source not found';
  end if;
  return v_src;
end fnc_unwrap;

end pkg_wrap;
/
