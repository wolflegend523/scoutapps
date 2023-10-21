package com.example.squirrelscout.data.objects;

import android.content.Context;

import com.caverock.androidsvg.SVG;
import com.caverock.androidsvg.SVGParseException;
import com.diskuv.dksdk.ffi.java.Clazz;
import com.diskuv.dksdk.ffi.java.Com;
import com.diskuv.dksdk.ffi.java.Instance;
import com.diskuv.dksdk.ffi.java.Method;
import com.diskuv.dksdk.schema.StdSchema;
import com.example.squirrelscout.data.DatabaseStorage;

import org.capnproto.MessageBuilder;
import org.capnproto.MessageReader;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;

public class ScoutBridge {
    private static volatile Clazz clazz;
    private static final Method M_CREATE_OBJECT = Method.ofName("create_object");
    private static final Method M_GENERATE_QR_CODE = Method.ofName("generate_qr_code");
    private static final Method M_GET_TEAM_FOR_MATCH_AND_POSITION = Method.ofName("get_team_for_match_and_position");
    private static final Method M_INSERT_SCOUTED_DATA = Method.ofName("insert_scouted_data");
    private static final Method M_LOAD_JSON_MATCH_SCHEDULE = Method.ofName("load_json_match_schedule");
    private final Instance instance;

    private ScoutBridge(Instance instance) {
        this.instance = instance;
    }

    /* Init <Clazz> singleton */
    private static void init(Com com) {
        if (clazz == null) {
            synchronized (ScoutBridge.class) {
                if (clazz == null) {
                    clazz = com.borrowClassUntilFinalized("SquirrelScout::Bridge");
                }
            }
        }
    }

    public static ScoutBridge create(Com com, Context context) {
        init(com);

        /* find where the database should be */
        final File databasePath;
        try {
            databasePath = DatabaseStorage.databasePath(context);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        if (databasePath == null) {
            throw new RuntimeException("Not enough space to use the scouting database");
        }

        /* args: databasePath=[DATA] */
        MessageBuilder arguments = Com.newMessageBuilder();
        StdSchema.St.Builder builder = arguments.initRoot(StdSchema.St.factory);
        builder.setI1(databasePath.getPath());

        /* return: <new object>
         *      [type GenericReturn = unset | value of 'value | newObject of ComObject]
         *      We only need [newObject of ComObject], but we still have to specific
         *      something for the ['value] generic type parameter.
         */
        MessageReader response = clazz.call(M_CREATE_OBJECT, arguments);
        StdSchema.GenericReturn.Reader<StdSchema.Su8.Reader> grReader =
                response.getRoot(StdSchema.GenericReturn.newFactory(StdSchema.Su8.factory));
        StdSchema.ComObject.Reader reader = grReader.getNewObject();
        return new ScoutBridge(clazz.takeInstanceObjectUntilFinalized(reader));
    }

    public static SVG generateQrCode(Com com, byte[] blob) {
        init(com);

        /* args: [DATA] */
        MessageBuilder arguments = Com.newMessageBuilder();
        StdSchema.Sd.Builder builder = arguments.initRoot(StdSchema.Sd.factory);
        builder.setI1(blob);

        /* return: [DATA] */
        MessageReader response = clazz.call(M_GENERATE_QR_CODE, arguments);
        StdSchema.GenericReturn.Reader<StdSchema.Sd.Reader> grReader =
                response.getRoot(StdSchema.GenericReturn.newFactory(StdSchema.Sd.factory));
        StdSchema.Sd.Reader reader = grReader.getValue();
        byte[] responseBytes = reader.getI1().toArray();

        /* translate to dev-friendly response */
        try {
            return SVG.getFromInputStream(new ByteArrayInputStream(responseBytes));
        } catch (SVGParseException e) {
            throw new RuntimeException(e);
        }
    }
}
