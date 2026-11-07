-- update_product_skus.sql
-- Script cập nhật mã sản phẩm (SKU) theo cấu trúc: [Tên viết tắt NCC chữ Latin] + [STT]
-- Tự động sinh bởi update-product-skus.js
-- LƯU Ý: Giữ nguyên Products.Name (tên sản phẩm gốc), chỉ cập nhật cột Sku.

BEGIN;

-- Bước 1: Gán SKU tạm thời để tránh xung đột UNIQUE INDEX ("IX_Products_Sku") trong quá trình cập nhật hàng loạt
UPDATE "Products" SET "Sku" = '__TMP_SKU_2__' WHERE "Id" = 2;
UPDATE "Products" SET "Sku" = '__TMP_SKU_3__' WHERE "Id" = 3;
UPDATE "Products" SET "Sku" = '__TMP_SKU_4__' WHERE "Id" = 4;
UPDATE "Products" SET "Sku" = '__TMP_SKU_5__' WHERE "Id" = 5;
UPDATE "Products" SET "Sku" = '__TMP_SKU_6__' WHERE "Id" = 6;
UPDATE "Products" SET "Sku" = '__TMP_SKU_7__' WHERE "Id" = 7;
UPDATE "Products" SET "Sku" = '__TMP_SKU_8__' WHERE "Id" = 8;
UPDATE "Products" SET "Sku" = '__TMP_SKU_9__' WHERE "Id" = 9;
UPDATE "Products" SET "Sku" = '__TMP_SKU_10__' WHERE "Id" = 10;
UPDATE "Products" SET "Sku" = '__TMP_SKU_11__' WHERE "Id" = 11;
UPDATE "Products" SET "Sku" = '__TMP_SKU_12__' WHERE "Id" = 12;
UPDATE "Products" SET "Sku" = '__TMP_SKU_13__' WHERE "Id" = 13;
UPDATE "Products" SET "Sku" = '__TMP_SKU_14__' WHERE "Id" = 14;
UPDATE "Products" SET "Sku" = '__TMP_SKU_15__' WHERE "Id" = 15;
UPDATE "Products" SET "Sku" = '__TMP_SKU_16__' WHERE "Id" = 16;
UPDATE "Products" SET "Sku" = '__TMP_SKU_17__' WHERE "Id" = 17;
UPDATE "Products" SET "Sku" = '__TMP_SKU_18__' WHERE "Id" = 18;
UPDATE "Products" SET "Sku" = '__TMP_SKU_19__' WHERE "Id" = 19;
UPDATE "Products" SET "Sku" = '__TMP_SKU_20__' WHERE "Id" = 20;
UPDATE "Products" SET "Sku" = '__TMP_SKU_21__' WHERE "Id" = 21;
UPDATE "Products" SET "Sku" = '__TMP_SKU_22__' WHERE "Id" = 22;
UPDATE "Products" SET "Sku" = '__TMP_SKU_23__' WHERE "Id" = 23;
UPDATE "Products" SET "Sku" = '__TMP_SKU_24__' WHERE "Id" = 24;
UPDATE "Products" SET "Sku" = '__TMP_SKU_25__' WHERE "Id" = 25;
UPDATE "Products" SET "Sku" = '__TMP_SKU_26__' WHERE "Id" = 26;
UPDATE "Products" SET "Sku" = '__TMP_SKU_27__' WHERE "Id" = 27;
UPDATE "Products" SET "Sku" = '__TMP_SKU_28__' WHERE "Id" = 28;
UPDATE "Products" SET "Sku" = '__TMP_SKU_29__' WHERE "Id" = 29;
UPDATE "Products" SET "Sku" = '__TMP_SKU_30__' WHERE "Id" = 30;
UPDATE "Products" SET "Sku" = '__TMP_SKU_31__' WHERE "Id" = 31;
UPDATE "Products" SET "Sku" = '__TMP_SKU_32__' WHERE "Id" = 32;
UPDATE "Products" SET "Sku" = '__TMP_SKU_33__' WHERE "Id" = 33;
UPDATE "Products" SET "Sku" = '__TMP_SKU_34__' WHERE "Id" = 34;
UPDATE "Products" SET "Sku" = '__TMP_SKU_35__' WHERE "Id" = 35;
UPDATE "Products" SET "Sku" = '__TMP_SKU_36__' WHERE "Id" = 36;
UPDATE "Products" SET "Sku" = '__TMP_SKU_37__' WHERE "Id" = 37;
UPDATE "Products" SET "Sku" = '__TMP_SKU_38__' WHERE "Id" = 38;
UPDATE "Products" SET "Sku" = '__TMP_SKU_39__' WHERE "Id" = 39;
UPDATE "Products" SET "Sku" = '__TMP_SKU_40__' WHERE "Id" = 40;
UPDATE "Products" SET "Sku" = '__TMP_SKU_41__' WHERE "Id" = 41;
UPDATE "Products" SET "Sku" = '__TMP_SKU_42__' WHERE "Id" = 42;
UPDATE "Products" SET "Sku" = '__TMP_SKU_43__' WHERE "Id" = 43;
UPDATE "Products" SET "Sku" = '__TMP_SKU_44__' WHERE "Id" = 44;
UPDATE "Products" SET "Sku" = '__TMP_SKU_45__' WHERE "Id" = 45;
UPDATE "Products" SET "Sku" = '__TMP_SKU_46__' WHERE "Id" = 46;
UPDATE "Products" SET "Sku" = '__TMP_SKU_47__' WHERE "Id" = 47;
UPDATE "Products" SET "Sku" = '__TMP_SKU_48__' WHERE "Id" = 48;
UPDATE "Products" SET "Sku" = '__TMP_SKU_49__' WHERE "Id" = 49;
UPDATE "Products" SET "Sku" = '__TMP_SKU_50__' WHERE "Id" = 50;
UPDATE "Products" SET "Sku" = '__TMP_SKU_51__' WHERE "Id" = 51;
UPDATE "Products" SET "Sku" = '__TMP_SKU_52__' WHERE "Id" = 52;
UPDATE "Products" SET "Sku" = '__TMP_SKU_53__' WHERE "Id" = 53;
UPDATE "Products" SET "Sku" = '__TMP_SKU_54__' WHERE "Id" = 54;
UPDATE "Products" SET "Sku" = '__TMP_SKU_55__' WHERE "Id" = 55;
UPDATE "Products" SET "Sku" = '__TMP_SKU_56__' WHERE "Id" = 56;
UPDATE "Products" SET "Sku" = '__TMP_SKU_57__' WHERE "Id" = 57;
UPDATE "Products" SET "Sku" = '__TMP_SKU_58__' WHERE "Id" = 58;
UPDATE "Products" SET "Sku" = '__TMP_SKU_59__' WHERE "Id" = 59;
UPDATE "Products" SET "Sku" = '__TMP_SKU_60__' WHERE "Id" = 60;
UPDATE "Products" SET "Sku" = '__TMP_SKU_61__' WHERE "Id" = 61;
UPDATE "Products" SET "Sku" = '__TMP_SKU_62__' WHERE "Id" = 62;
UPDATE "Products" SET "Sku" = '__TMP_SKU_63__' WHERE "Id" = 63;
UPDATE "Products" SET "Sku" = '__TMP_SKU_64__' WHERE "Id" = 64;
UPDATE "Products" SET "Sku" = '__TMP_SKU_65__' WHERE "Id" = 65;
UPDATE "Products" SET "Sku" = '__TMP_SKU_66__' WHERE "Id" = 66;
UPDATE "Products" SET "Sku" = '__TMP_SKU_67__' WHERE "Id" = 67;
UPDATE "Products" SET "Sku" = '__TMP_SKU_68__' WHERE "Id" = 68;
UPDATE "Products" SET "Sku" = '__TMP_SKU_69__' WHERE "Id" = 69;
UPDATE "Products" SET "Sku" = '__TMP_SKU_70__' WHERE "Id" = 70;
UPDATE "Products" SET "Sku" = '__TMP_SKU_71__' WHERE "Id" = 71;
UPDATE "Products" SET "Sku" = '__TMP_SKU_72__' WHERE "Id" = 72;
UPDATE "Products" SET "Sku" = '__TMP_SKU_73__' WHERE "Id" = 73;
UPDATE "Products" SET "Sku" = '__TMP_SKU_74__' WHERE "Id" = 74;
UPDATE "Products" SET "Sku" = '__TMP_SKU_75__' WHERE "Id" = 75;
UPDATE "Products" SET "Sku" = '__TMP_SKU_76__' WHERE "Id" = 76;
UPDATE "Products" SET "Sku" = '__TMP_SKU_77__' WHERE "Id" = 77;
UPDATE "Products" SET "Sku" = '__TMP_SKU_78__' WHERE "Id" = 78;
UPDATE "Products" SET "Sku" = '__TMP_SKU_79__' WHERE "Id" = 79;
UPDATE "Products" SET "Sku" = '__TMP_SKU_80__' WHERE "Id" = 80;
UPDATE "Products" SET "Sku" = '__TMP_SKU_81__' WHERE "Id" = 81;
UPDATE "Products" SET "Sku" = '__TMP_SKU_82__' WHERE "Id" = 82;
UPDATE "Products" SET "Sku" = '__TMP_SKU_83__' WHERE "Id" = 83;
UPDATE "Products" SET "Sku" = '__TMP_SKU_84__' WHERE "Id" = 84;
UPDATE "Products" SET "Sku" = '__TMP_SKU_85__' WHERE "Id" = 85;
UPDATE "Products" SET "Sku" = '__TMP_SKU_86__' WHERE "Id" = 86;
UPDATE "Products" SET "Sku" = '__TMP_SKU_87__' WHERE "Id" = 87;
UPDATE "Products" SET "Sku" = '__TMP_SKU_88__' WHERE "Id" = 88;
UPDATE "Products" SET "Sku" = '__TMP_SKU_89__' WHERE "Id" = 89;
UPDATE "Products" SET "Sku" = '__TMP_SKU_90__' WHERE "Id" = 90;
UPDATE "Products" SET "Sku" = '__TMP_SKU_91__' WHERE "Id" = 91;
UPDATE "Products" SET "Sku" = '__TMP_SKU_92__' WHERE "Id" = 92;
UPDATE "Products" SET "Sku" = '__TMP_SKU_93__' WHERE "Id" = 93;
UPDATE "Products" SET "Sku" = '__TMP_SKU_94__' WHERE "Id" = 94;
UPDATE "Products" SET "Sku" = '__TMP_SKU_95__' WHERE "Id" = 95;
UPDATE "Products" SET "Sku" = '__TMP_SKU_96__' WHERE "Id" = 96;
UPDATE "Products" SET "Sku" = '__TMP_SKU_97__' WHERE "Id" = 97;
UPDATE "Products" SET "Sku" = '__TMP_SKU_98__' WHERE "Id" = 98;
UPDATE "Products" SET "Sku" = '__TMP_SKU_99__' WHERE "Id" = 99;
UPDATE "Products" SET "Sku" = '__TMP_SKU_100__' WHERE "Id" = 100;
UPDATE "Products" SET "Sku" = '__TMP_SKU_101__' WHERE "Id" = 101;
UPDATE "Products" SET "Sku" = '__TMP_SKU_102__' WHERE "Id" = 102;
UPDATE "Products" SET "Sku" = '__TMP_SKU_103__' WHERE "Id" = 103;
UPDATE "Products" SET "Sku" = '__TMP_SKU_104__' WHERE "Id" = 104;
UPDATE "Products" SET "Sku" = '__TMP_SKU_105__' WHERE "Id" = 105;
UPDATE "Products" SET "Sku" = '__TMP_SKU_106__' WHERE "Id" = 106;
UPDATE "Products" SET "Sku" = '__TMP_SKU_107__' WHERE "Id" = 107;
UPDATE "Products" SET "Sku" = '__TMP_SKU_108__' WHERE "Id" = 108;
UPDATE "Products" SET "Sku" = '__TMP_SKU_109__' WHERE "Id" = 109;
UPDATE "Products" SET "Sku" = '__TMP_SKU_110__' WHERE "Id" = 110;
UPDATE "Products" SET "Sku" = '__TMP_SKU_111__' WHERE "Id" = 111;
UPDATE "Products" SET "Sku" = '__TMP_SKU_112__' WHERE "Id" = 112;
UPDATE "Products" SET "Sku" = '__TMP_SKU_113__' WHERE "Id" = 113;
UPDATE "Products" SET "Sku" = '__TMP_SKU_114__' WHERE "Id" = 114;
UPDATE "Products" SET "Sku" = '__TMP_SKU_115__' WHERE "Id" = 115;
UPDATE "Products" SET "Sku" = '__TMP_SKU_116__' WHERE "Id" = 116;
UPDATE "Products" SET "Sku" = '__TMP_SKU_117__' WHERE "Id" = 117;
UPDATE "Products" SET "Sku" = '__TMP_SKU_118__' WHERE "Id" = 118;
UPDATE "Products" SET "Sku" = '__TMP_SKU_119__' WHERE "Id" = 119;
UPDATE "Products" SET "Sku" = '__TMP_SKU_120__' WHERE "Id" = 120;
UPDATE "Products" SET "Sku" = '__TMP_SKU_121__' WHERE "Id" = 121;
UPDATE "Products" SET "Sku" = '__TMP_SKU_122__' WHERE "Id" = 122;
UPDATE "Products" SET "Sku" = '__TMP_SKU_123__' WHERE "Id" = 123;
UPDATE "Products" SET "Sku" = '__TMP_SKU_124__' WHERE "Id" = 124;
UPDATE "Products" SET "Sku" = '__TMP_SKU_125__' WHERE "Id" = 125;
UPDATE "Products" SET "Sku" = '__TMP_SKU_126__' WHERE "Id" = 126;
UPDATE "Products" SET "Sku" = '__TMP_SKU_127__' WHERE "Id" = 127;
UPDATE "Products" SET "Sku" = '__TMP_SKU_128__' WHERE "Id" = 128;
UPDATE "Products" SET "Sku" = '__TMP_SKU_129__' WHERE "Id" = 129;
UPDATE "Products" SET "Sku" = '__TMP_SKU_130__' WHERE "Id" = 130;
UPDATE "Products" SET "Sku" = '__TMP_SKU_131__' WHERE "Id" = 131;
UPDATE "Products" SET "Sku" = '__TMP_SKU_132__' WHERE "Id" = 132;
UPDATE "Products" SET "Sku" = '__TMP_SKU_133__' WHERE "Id" = 133;
UPDATE "Products" SET "Sku" = '__TMP_SKU_134__' WHERE "Id" = 134;
UPDATE "Products" SET "Sku" = '__TMP_SKU_135__' WHERE "Id" = 135;
UPDATE "Products" SET "Sku" = '__TMP_SKU_136__' WHERE "Id" = 136;
UPDATE "Products" SET "Sku" = '__TMP_SKU_137__' WHERE "Id" = 137;
UPDATE "Products" SET "Sku" = '__TMP_SKU_138__' WHERE "Id" = 138;
UPDATE "Products" SET "Sku" = '__TMP_SKU_139__' WHERE "Id" = 139;
UPDATE "Products" SET "Sku" = '__TMP_SKU_140__' WHERE "Id" = 140;
UPDATE "Products" SET "Sku" = '__TMP_SKU_141__' WHERE "Id" = 141;
UPDATE "Products" SET "Sku" = '__TMP_SKU_142__' WHERE "Id" = 142;
UPDATE "Products" SET "Sku" = '__TMP_SKU_143__' WHERE "Id" = 143;
UPDATE "Products" SET "Sku" = '__TMP_SKU_144__' WHERE "Id" = 144;
UPDATE "Products" SET "Sku" = '__TMP_SKU_145__' WHERE "Id" = 145;
UPDATE "Products" SET "Sku" = '__TMP_SKU_146__' WHERE "Id" = 146;
UPDATE "Products" SET "Sku" = '__TMP_SKU_147__' WHERE "Id" = 147;
UPDATE "Products" SET "Sku" = '__TMP_SKU_148__' WHERE "Id" = 148;
UPDATE "Products" SET "Sku" = '__TMP_SKU_149__' WHERE "Id" = 149;
UPDATE "Products" SET "Sku" = '__TMP_SKU_150__' WHERE "Id" = 150;
UPDATE "Products" SET "Sku" = '__TMP_SKU_151__' WHERE "Id" = 151;
UPDATE "Products" SET "Sku" = '__TMP_SKU_152__' WHERE "Id" = 152;
UPDATE "Products" SET "Sku" = '__TMP_SKU_153__' WHERE "Id" = 153;
UPDATE "Products" SET "Sku" = '__TMP_SKU_154__' WHERE "Id" = 154;
UPDATE "Products" SET "Sku" = '__TMP_SKU_155__' WHERE "Id" = 155;
UPDATE "Products" SET "Sku" = '__TMP_SKU_156__' WHERE "Id" = 156;
UPDATE "Products" SET "Sku" = '__TMP_SKU_157__' WHERE "Id" = 157;
UPDATE "Products" SET "Sku" = '__TMP_SKU_158__' WHERE "Id" = 158;
UPDATE "Products" SET "Sku" = '__TMP_SKU_159__' WHERE "Id" = 159;
UPDATE "Products" SET "Sku" = '__TMP_SKU_160__' WHERE "Id" = 160;
UPDATE "Products" SET "Sku" = '__TMP_SKU_161__' WHERE "Id" = 161;
UPDATE "Products" SET "Sku" = '__TMP_SKU_162__' WHERE "Id" = 162;
UPDATE "Products" SET "Sku" = '__TMP_SKU_163__' WHERE "Id" = 163;
UPDATE "Products" SET "Sku" = '__TMP_SKU_164__' WHERE "Id" = 164;
UPDATE "Products" SET "Sku" = '__TMP_SKU_165__' WHERE "Id" = 165;
UPDATE "Products" SET "Sku" = '__TMP_SKU_166__' WHERE "Id" = 166;
UPDATE "Products" SET "Sku" = '__TMP_SKU_167__' WHERE "Id" = 167;
UPDATE "Products" SET "Sku" = '__TMP_SKU_168__' WHERE "Id" = 168;
UPDATE "Products" SET "Sku" = '__TMP_SKU_169__' WHERE "Id" = 169;
UPDATE "Products" SET "Sku" = '__TMP_SKU_170__' WHERE "Id" = 170;
UPDATE "Products" SET "Sku" = '__TMP_SKU_171__' WHERE "Id" = 171;
UPDATE "Products" SET "Sku" = '__TMP_SKU_172__' WHERE "Id" = 172;
UPDATE "Products" SET "Sku" = '__TMP_SKU_173__' WHERE "Id" = 173;
UPDATE "Products" SET "Sku" = '__TMP_SKU_174__' WHERE "Id" = 174;
UPDATE "Products" SET "Sku" = '__TMP_SKU_175__' WHERE "Id" = 175;
UPDATE "Products" SET "Sku" = '__TMP_SKU_176__' WHERE "Id" = 176;
UPDATE "Products" SET "Sku" = '__TMP_SKU_177__' WHERE "Id" = 177;
UPDATE "Products" SET "Sku" = '__TMP_SKU_178__' WHERE "Id" = 178;
UPDATE "Products" SET "Sku" = '__TMP_SKU_179__' WHERE "Id" = 179;
UPDATE "Products" SET "Sku" = '__TMP_SKU_180__' WHERE "Id" = 180;
UPDATE "Products" SET "Sku" = '__TMP_SKU_181__' WHERE "Id" = 181;
UPDATE "Products" SET "Sku" = '__TMP_SKU_182__' WHERE "Id" = 182;
UPDATE "Products" SET "Sku" = '__TMP_SKU_183__' WHERE "Id" = 183;
UPDATE "Products" SET "Sku" = '__TMP_SKU_184__' WHERE "Id" = 184;
UPDATE "Products" SET "Sku" = '__TMP_SKU_185__' WHERE "Id" = 185;
UPDATE "Products" SET "Sku" = '__TMP_SKU_186__' WHERE "Id" = 186;
UPDATE "Products" SET "Sku" = '__TMP_SKU_187__' WHERE "Id" = 187;
UPDATE "Products" SET "Sku" = '__TMP_SKU_188__' WHERE "Id" = 188;
UPDATE "Products" SET "Sku" = '__TMP_SKU_189__' WHERE "Id" = 189;
UPDATE "Products" SET "Sku" = '__TMP_SKU_190__' WHERE "Id" = 190;
UPDATE "Products" SET "Sku" = '__TMP_SKU_191__' WHERE "Id" = 191;
UPDATE "Products" SET "Sku" = '__TMP_SKU_192__' WHERE "Id" = 192;
UPDATE "Products" SET "Sku" = '__TMP_SKU_193__' WHERE "Id" = 193;
UPDATE "Products" SET "Sku" = '__TMP_SKU_194__' WHERE "Id" = 194;
UPDATE "Products" SET "Sku" = '__TMP_SKU_195__' WHERE "Id" = 195;
UPDATE "Products" SET "Sku" = '__TMP_SKU_196__' WHERE "Id" = 196;
UPDATE "Products" SET "Sku" = '__TMP_SKU_197__' WHERE "Id" = 197;
UPDATE "Products" SET "Sku" = '__TMP_SKU_198__' WHERE "Id" = 198;
UPDATE "Products" SET "Sku" = '__TMP_SKU_199__' WHERE "Id" = 199;
UPDATE "Products" SET "Sku" = '__TMP_SKU_200__' WHERE "Id" = 200;
UPDATE "Products" SET "Sku" = '__TMP_SKU_201__' WHERE "Id" = 201;
UPDATE "Products" SET "Sku" = '__TMP_SKU_202__' WHERE "Id" = 202;
UPDATE "Products" SET "Sku" = '__TMP_SKU_203__' WHERE "Id" = 203;
UPDATE "Products" SET "Sku" = '__TMP_SKU_204__' WHERE "Id" = 204;
UPDATE "Products" SET "Sku" = '__TMP_SKU_205__' WHERE "Id" = 205;
UPDATE "Products" SET "Sku" = '__TMP_SKU_206__' WHERE "Id" = 206;
UPDATE "Products" SET "Sku" = '__TMP_SKU_207__' WHERE "Id" = 207;
UPDATE "Products" SET "Sku" = '__TMP_SKU_208__' WHERE "Id" = 208;
UPDATE "Products" SET "Sku" = '__TMP_SKU_209__' WHERE "Id" = 209;
UPDATE "Products" SET "Sku" = '__TMP_SKU_210__' WHERE "Id" = 210;
UPDATE "Products" SET "Sku" = '__TMP_SKU_211__' WHERE "Id" = 211;
UPDATE "Products" SET "Sku" = '__TMP_SKU_212__' WHERE "Id" = 212;
UPDATE "Products" SET "Sku" = '__TMP_SKU_213__' WHERE "Id" = 213;
UPDATE "Products" SET "Sku" = '__TMP_SKU_214__' WHERE "Id" = 214;
UPDATE "Products" SET "Sku" = '__TMP_SKU_215__' WHERE "Id" = 215;
UPDATE "Products" SET "Sku" = '__TMP_SKU_216__' WHERE "Id" = 216;
UPDATE "Products" SET "Sku" = '__TMP_SKU_217__' WHERE "Id" = 217;
UPDATE "Products" SET "Sku" = '__TMP_SKU_218__' WHERE "Id" = 218;
UPDATE "Products" SET "Sku" = '__TMP_SKU_219__' WHERE "Id" = 219;
UPDATE "Products" SET "Sku" = '__TMP_SKU_220__' WHERE "Id" = 220;
UPDATE "Products" SET "Sku" = '__TMP_SKU_221__' WHERE "Id" = 221;
UPDATE "Products" SET "Sku" = '__TMP_SKU_222__' WHERE "Id" = 222;
UPDATE "Products" SET "Sku" = '__TMP_SKU_223__' WHERE "Id" = 223;
UPDATE "Products" SET "Sku" = '__TMP_SKU_224__' WHERE "Id" = 224;
UPDATE "Products" SET "Sku" = '__TMP_SKU_225__' WHERE "Id" = 225;
UPDATE "Products" SET "Sku" = '__TMP_SKU_226__' WHERE "Id" = 226;
UPDATE "Products" SET "Sku" = '__TMP_SKU_227__' WHERE "Id" = 227;
UPDATE "Products" SET "Sku" = '__TMP_SKU_228__' WHERE "Id" = 228;
UPDATE "Products" SET "Sku" = '__TMP_SKU_229__' WHERE "Id" = 229;
UPDATE "Products" SET "Sku" = '__TMP_SKU_230__' WHERE "Id" = 230;
UPDATE "Products" SET "Sku" = '__TMP_SKU_231__' WHERE "Id" = 231;
UPDATE "Products" SET "Sku" = '__TMP_SKU_232__' WHERE "Id" = 232;
UPDATE "Products" SET "Sku" = '__TMP_SKU_233__' WHERE "Id" = 233;
UPDATE "Products" SET "Sku" = '__TMP_SKU_234__' WHERE "Id" = 234;
UPDATE "Products" SET "Sku" = '__TMP_SKU_235__' WHERE "Id" = 235;
UPDATE "Products" SET "Sku" = '__TMP_SKU_236__' WHERE "Id" = 236;
UPDATE "Products" SET "Sku" = '__TMP_SKU_237__' WHERE "Id" = 237;
UPDATE "Products" SET "Sku" = '__TMP_SKU_238__' WHERE "Id" = 238;
UPDATE "Products" SET "Sku" = '__TMP_SKU_239__' WHERE "Id" = 239;
UPDATE "Products" SET "Sku" = '__TMP_SKU_240__' WHERE "Id" = 240;
UPDATE "Products" SET "Sku" = '__TMP_SKU_241__' WHERE "Id" = 241;
UPDATE "Products" SET "Sku" = '__TMP_SKU_242__' WHERE "Id" = 242;
UPDATE "Products" SET "Sku" = '__TMP_SKU_243__' WHERE "Id" = 243;
UPDATE "Products" SET "Sku" = '__TMP_SKU_244__' WHERE "Id" = 244;
UPDATE "Products" SET "Sku" = '__TMP_SKU_245__' WHERE "Id" = 245;
UPDATE "Products" SET "Sku" = '__TMP_SKU_246__' WHERE "Id" = 246;
UPDATE "Products" SET "Sku" = '__TMP_SKU_247__' WHERE "Id" = 247;
UPDATE "Products" SET "Sku" = '__TMP_SKU_248__' WHERE "Id" = 248;
UPDATE "Products" SET "Sku" = '__TMP_SKU_249__' WHERE "Id" = 249;
UPDATE "Products" SET "Sku" = '__TMP_SKU_250__' WHERE "Id" = 250;
UPDATE "Products" SET "Sku" = '__TMP_SKU_251__' WHERE "Id" = 251;
UPDATE "Products" SET "Sku" = '__TMP_SKU_252__' WHERE "Id" = 252;
UPDATE "Products" SET "Sku" = '__TMP_SKU_253__' WHERE "Id" = 253;
UPDATE "Products" SET "Sku" = '__TMP_SKU_254__' WHERE "Id" = 254;
UPDATE "Products" SET "Sku" = '__TMP_SKU_255__' WHERE "Id" = 255;
UPDATE "Products" SET "Sku" = '__TMP_SKU_256__' WHERE "Id" = 256;
UPDATE "Products" SET "Sku" = '__TMP_SKU_257__' WHERE "Id" = 257;
UPDATE "Products" SET "Sku" = '__TMP_SKU_258__' WHERE "Id" = 258;
UPDATE "Products" SET "Sku" = '__TMP_SKU_259__' WHERE "Id" = 259;
UPDATE "Products" SET "Sku" = '__TMP_SKU_260__' WHERE "Id" = 260;
UPDATE "Products" SET "Sku" = '__TMP_SKU_261__' WHERE "Id" = 261;
UPDATE "Products" SET "Sku" = '__TMP_SKU_262__' WHERE "Id" = 262;
UPDATE "Products" SET "Sku" = '__TMP_SKU_263__' WHERE "Id" = 263;
UPDATE "Products" SET "Sku" = '__TMP_SKU_264__' WHERE "Id" = 264;
UPDATE "Products" SET "Sku" = '__TMP_SKU_265__' WHERE "Id" = 265;
UPDATE "Products" SET "Sku" = '__TMP_SKU_266__' WHERE "Id" = 266;
UPDATE "Products" SET "Sku" = '__TMP_SKU_267__' WHERE "Id" = 267;
UPDATE "Products" SET "Sku" = '__TMP_SKU_268__' WHERE "Id" = 268;
UPDATE "Products" SET "Sku" = '__TMP_SKU_269__' WHERE "Id" = 269;
UPDATE "Products" SET "Sku" = '__TMP_SKU_270__' WHERE "Id" = 270;
UPDATE "Products" SET "Sku" = '__TMP_SKU_271__' WHERE "Id" = 271;
UPDATE "Products" SET "Sku" = '__TMP_SKU_272__' WHERE "Id" = 272;
UPDATE "Products" SET "Sku" = '__TMP_SKU_273__' WHERE "Id" = 273;
UPDATE "Products" SET "Sku" = '__TMP_SKU_274__' WHERE "Id" = 274;
UPDATE "Products" SET "Sku" = '__TMP_SKU_275__' WHERE "Id" = 275;
UPDATE "Products" SET "Sku" = '__TMP_SKU_276__' WHERE "Id" = 276;
UPDATE "Products" SET "Sku" = '__TMP_SKU_277__' WHERE "Id" = 277;
UPDATE "Products" SET "Sku" = '__TMP_SKU_278__' WHERE "Id" = 278;
UPDATE "Products" SET "Sku" = '__TMP_SKU_279__' WHERE "Id" = 279;
UPDATE "Products" SET "Sku" = '__TMP_SKU_280__' WHERE "Id" = 280;
UPDATE "Products" SET "Sku" = '__TMP_SKU_281__' WHERE "Id" = 281;
UPDATE "Products" SET "Sku" = '__TMP_SKU_282__' WHERE "Id" = 282;
UPDATE "Products" SET "Sku" = '__TMP_SKU_283__' WHERE "Id" = 283;
UPDATE "Products" SET "Sku" = '__TMP_SKU_284__' WHERE "Id" = 284;
UPDATE "Products" SET "Sku" = '__TMP_SKU_285__' WHERE "Id" = 285;
UPDATE "Products" SET "Sku" = '__TMP_SKU_286__' WHERE "Id" = 286;
UPDATE "Products" SET "Sku" = '__TMP_SKU_287__' WHERE "Id" = 287;
UPDATE "Products" SET "Sku" = '__TMP_SKU_288__' WHERE "Id" = 288;
UPDATE "Products" SET "Sku" = '__TMP_SKU_289__' WHERE "Id" = 289;
UPDATE "Products" SET "Sku" = '__TMP_SKU_290__' WHERE "Id" = 290;
UPDATE "Products" SET "Sku" = '__TMP_SKU_291__' WHERE "Id" = 291;
UPDATE "Products" SET "Sku" = '__TMP_SKU_292__' WHERE "Id" = 292;
UPDATE "Products" SET "Sku" = '__TMP_SKU_293__' WHERE "Id" = 293;
UPDATE "Products" SET "Sku" = '__TMP_SKU_294__' WHERE "Id" = 294;
UPDATE "Products" SET "Sku" = '__TMP_SKU_295__' WHERE "Id" = 295;
UPDATE "Products" SET "Sku" = '__TMP_SKU_296__' WHERE "Id" = 296;
UPDATE "Products" SET "Sku" = '__TMP_SKU_297__' WHERE "Id" = 297;
UPDATE "Products" SET "Sku" = '__TMP_SKU_298__' WHERE "Id" = 298;
UPDATE "Products" SET "Sku" = '__TMP_SKU_299__' WHERE "Id" = 299;
UPDATE "Products" SET "Sku" = '__TMP_SKU_300__' WHERE "Id" = 300;
UPDATE "Products" SET "Sku" = '__TMP_SKU_301__' WHERE "Id" = 301;
UPDATE "Products" SET "Sku" = '__TMP_SKU_302__' WHERE "Id" = 302;
UPDATE "Products" SET "Sku" = '__TMP_SKU_303__' WHERE "Id" = 303;
UPDATE "Products" SET "Sku" = '__TMP_SKU_304__' WHERE "Id" = 304;
UPDATE "Products" SET "Sku" = '__TMP_SKU_305__' WHERE "Id" = 305;
UPDATE "Products" SET "Sku" = '__TMP_SKU_306__' WHERE "Id" = 306;
UPDATE "Products" SET "Sku" = '__TMP_SKU_307__' WHERE "Id" = 307;
UPDATE "Products" SET "Sku" = '__TMP_SKU_308__' WHERE "Id" = 308;
UPDATE "Products" SET "Sku" = '__TMP_SKU_309__' WHERE "Id" = 309;
UPDATE "Products" SET "Sku" = '__TMP_SKU_310__' WHERE "Id" = 310;
UPDATE "Products" SET "Sku" = '__TMP_SKU_311__' WHERE "Id" = 311;
UPDATE "Products" SET "Sku" = '__TMP_SKU_312__' WHERE "Id" = 312;
UPDATE "Products" SET "Sku" = '__TMP_SKU_313__' WHERE "Id" = 313;
UPDATE "Products" SET "Sku" = '__TMP_SKU_314__' WHERE "Id" = 314;
UPDATE "Products" SET "Sku" = '__TMP_SKU_315__' WHERE "Id" = 315;
UPDATE "Products" SET "Sku" = '__TMP_SKU_316__' WHERE "Id" = 316;
UPDATE "Products" SET "Sku" = '__TMP_SKU_317__' WHERE "Id" = 317;
UPDATE "Products" SET "Sku" = '__TMP_SKU_318__' WHERE "Id" = 318;
UPDATE "Products" SET "Sku" = '__TMP_SKU_319__' WHERE "Id" = 319;
UPDATE "Products" SET "Sku" = '__TMP_SKU_320__' WHERE "Id" = 320;
UPDATE "Products" SET "Sku" = '__TMP_SKU_321__' WHERE "Id" = 321;
UPDATE "Products" SET "Sku" = '__TMP_SKU_322__' WHERE "Id" = 322;
UPDATE "Products" SET "Sku" = '__TMP_SKU_323__' WHERE "Id" = 323;
UPDATE "Products" SET "Sku" = '__TMP_SKU_324__' WHERE "Id" = 324;
UPDATE "Products" SET "Sku" = '__TMP_SKU_325__' WHERE "Id" = 325;
UPDATE "Products" SET "Sku" = '__TMP_SKU_326__' WHERE "Id" = 326;
UPDATE "Products" SET "Sku" = '__TMP_SKU_327__' WHERE "Id" = 327;
UPDATE "Products" SET "Sku" = '__TMP_SKU_328__' WHERE "Id" = 328;
UPDATE "Products" SET "Sku" = '__TMP_SKU_329__' WHERE "Id" = 329;
UPDATE "Products" SET "Sku" = '__TMP_SKU_330__' WHERE "Id" = 330;
UPDATE "Products" SET "Sku" = '__TMP_SKU_331__' WHERE "Id" = 331;
UPDATE "Products" SET "Sku" = '__TMP_SKU_332__' WHERE "Id" = 332;
UPDATE "Products" SET "Sku" = '__TMP_SKU_333__' WHERE "Id" = 333;
UPDATE "Products" SET "Sku" = '__TMP_SKU_334__' WHERE "Id" = 334;
UPDATE "Products" SET "Sku" = '__TMP_SKU_335__' WHERE "Id" = 335;
UPDATE "Products" SET "Sku" = '__TMP_SKU_336__' WHERE "Id" = 336;
UPDATE "Products" SET "Sku" = '__TMP_SKU_337__' WHERE "Id" = 337;
UPDATE "Products" SET "Sku" = '__TMP_SKU_338__' WHERE "Id" = 338;
UPDATE "Products" SET "Sku" = '__TMP_SKU_339__' WHERE "Id" = 339;
UPDATE "Products" SET "Sku" = '__TMP_SKU_340__' WHERE "Id" = 340;
UPDATE "Products" SET "Sku" = '__TMP_SKU_341__' WHERE "Id" = 341;
UPDATE "Products" SET "Sku" = '__TMP_SKU_342__' WHERE "Id" = 342;
UPDATE "Products" SET "Sku" = '__TMP_SKU_343__' WHERE "Id" = 343;
UPDATE "Products" SET "Sku" = '__TMP_SKU_344__' WHERE "Id" = 344;
UPDATE "Products" SET "Sku" = '__TMP_SKU_345__' WHERE "Id" = 345;
UPDATE "Products" SET "Sku" = '__TMP_SKU_346__' WHERE "Id" = 346;
UPDATE "Products" SET "Sku" = '__TMP_SKU_347__' WHERE "Id" = 347;
UPDATE "Products" SET "Sku" = '__TMP_SKU_348__' WHERE "Id" = 348;
UPDATE "Products" SET "Sku" = '__TMP_SKU_349__' WHERE "Id" = 349;
UPDATE "Products" SET "Sku" = '__TMP_SKU_350__' WHERE "Id" = 350;
UPDATE "Products" SET "Sku" = '__TMP_SKU_351__' WHERE "Id" = 351;
UPDATE "Products" SET "Sku" = '__TMP_SKU_352__' WHERE "Id" = 352;
UPDATE "Products" SET "Sku" = '__TMP_SKU_353__' WHERE "Id" = 353;
UPDATE "Products" SET "Sku" = '__TMP_SKU_354__' WHERE "Id" = 354;
UPDATE "Products" SET "Sku" = '__TMP_SKU_355__' WHERE "Id" = 355;
UPDATE "Products" SET "Sku" = '__TMP_SKU_356__' WHERE "Id" = 356;
UPDATE "Products" SET "Sku" = '__TMP_SKU_357__' WHERE "Id" = 357;
UPDATE "Products" SET "Sku" = '__TMP_SKU_358__' WHERE "Id" = 358;
UPDATE "Products" SET "Sku" = '__TMP_SKU_359__' WHERE "Id" = 359;
UPDATE "Products" SET "Sku" = '__TMP_SKU_360__' WHERE "Id" = 360;
UPDATE "Products" SET "Sku" = '__TMP_SKU_361__' WHERE "Id" = 361;
UPDATE "Products" SET "Sku" = '__TMP_SKU_362__' WHERE "Id" = 362;
UPDATE "Products" SET "Sku" = '__TMP_SKU_363__' WHERE "Id" = 363;
UPDATE "Products" SET "Sku" = '__TMP_SKU_364__' WHERE "Id" = 364;
UPDATE "Products" SET "Sku" = '__TMP_SKU_365__' WHERE "Id" = 365;
UPDATE "Products" SET "Sku" = '__TMP_SKU_366__' WHERE "Id" = 366;
UPDATE "Products" SET "Sku" = '__TMP_SKU_367__' WHERE "Id" = 367;
UPDATE "Products" SET "Sku" = '__TMP_SKU_368__' WHERE "Id" = 368;
UPDATE "Products" SET "Sku" = '__TMP_SKU_369__' WHERE "Id" = 369;
UPDATE "Products" SET "Sku" = '__TMP_SKU_370__' WHERE "Id" = 370;
UPDATE "Products" SET "Sku" = '__TMP_SKU_371__' WHERE "Id" = 371;
UPDATE "Products" SET "Sku" = '__TMP_SKU_372__' WHERE "Id" = 372;
UPDATE "Products" SET "Sku" = '__TMP_SKU_373__' WHERE "Id" = 373;
UPDATE "Products" SET "Sku" = '__TMP_SKU_374__' WHERE "Id" = 374;
UPDATE "Products" SET "Sku" = '__TMP_SKU_375__' WHERE "Id" = 375;
UPDATE "Products" SET "Sku" = '__TMP_SKU_376__' WHERE "Id" = 376;
UPDATE "Products" SET "Sku" = '__TMP_SKU_377__' WHERE "Id" = 377;
UPDATE "Products" SET "Sku" = '__TMP_SKU_378__' WHERE "Id" = 378;
UPDATE "Products" SET "Sku" = '__TMP_SKU_379__' WHERE "Id" = 379;
UPDATE "Products" SET "Sku" = '__TMP_SKU_380__' WHERE "Id" = 380;
UPDATE "Products" SET "Sku" = '__TMP_SKU_381__' WHERE "Id" = 381;
UPDATE "Products" SET "Sku" = '__TMP_SKU_382__' WHERE "Id" = 382;
UPDATE "Products" SET "Sku" = '__TMP_SKU_383__' WHERE "Id" = 383;
UPDATE "Products" SET "Sku" = '__TMP_SKU_384__' WHERE "Id" = 384;
UPDATE "Products" SET "Sku" = '__TMP_SKU_385__' WHERE "Id" = 385;
UPDATE "Products" SET "Sku" = '__TMP_SKU_386__' WHERE "Id" = 386;
UPDATE "Products" SET "Sku" = '__TMP_SKU_387__' WHERE "Id" = 387;
UPDATE "Products" SET "Sku" = '__TMP_SKU_388__' WHERE "Id" = 388;
UPDATE "Products" SET "Sku" = '__TMP_SKU_389__' WHERE "Id" = 389;
UPDATE "Products" SET "Sku" = '__TMP_SKU_390__' WHERE "Id" = 390;
UPDATE "Products" SET "Sku" = '__TMP_SKU_391__' WHERE "Id" = 391;
UPDATE "Products" SET "Sku" = '__TMP_SKU_392__' WHERE "Id" = 392;
UPDATE "Products" SET "Sku" = '__TMP_SKU_393__' WHERE "Id" = 393;
UPDATE "Products" SET "Sku" = '__TMP_SKU_394__' WHERE "Id" = 394;
UPDATE "Products" SET "Sku" = '__TMP_SKU_395__' WHERE "Id" = 395;
UPDATE "Products" SET "Sku" = '__TMP_SKU_396__' WHERE "Id" = 396;
UPDATE "Products" SET "Sku" = '__TMP_SKU_397__' WHERE "Id" = 397;
UPDATE "Products" SET "Sku" = '__TMP_SKU_398__' WHERE "Id" = 398;
UPDATE "Products" SET "Sku" = '__TMP_SKU_399__' WHERE "Id" = 399;
UPDATE "Products" SET "Sku" = '__TMP_SKU_400__' WHERE "Id" = 400;
UPDATE "Products" SET "Sku" = '__TMP_SKU_401__' WHERE "Id" = 401;
UPDATE "Products" SET "Sku" = '__TMP_SKU_402__' WHERE "Id" = 402;
UPDATE "Products" SET "Sku" = '__TMP_SKU_403__' WHERE "Id" = 403;
UPDATE "Products" SET "Sku" = '__TMP_SKU_404__' WHERE "Id" = 404;
UPDATE "Products" SET "Sku" = '__TMP_SKU_405__' WHERE "Id" = 405;
UPDATE "Products" SET "Sku" = '__TMP_SKU_406__' WHERE "Id" = 406;
UPDATE "Products" SET "Sku" = '__TMP_SKU_407__' WHERE "Id" = 407;
UPDATE "Products" SET "Sku" = '__TMP_SKU_408__' WHERE "Id" = 408;
UPDATE "Products" SET "Sku" = '__TMP_SKU_409__' WHERE "Id" = 409;
UPDATE "Products" SET "Sku" = '__TMP_SKU_410__' WHERE "Id" = 410;
UPDATE "Products" SET "Sku" = '__TMP_SKU_411__' WHERE "Id" = 411;
UPDATE "Products" SET "Sku" = '__TMP_SKU_412__' WHERE "Id" = 412;
UPDATE "Products" SET "Sku" = '__TMP_SKU_413__' WHERE "Id" = 413;
UPDATE "Products" SET "Sku" = '__TMP_SKU_414__' WHERE "Id" = 414;
UPDATE "Products" SET "Sku" = '__TMP_SKU_415__' WHERE "Id" = 415;
UPDATE "Products" SET "Sku" = '__TMP_SKU_416__' WHERE "Id" = 416;
UPDATE "Products" SET "Sku" = '__TMP_SKU_417__' WHERE "Id" = 417;
UPDATE "Products" SET "Sku" = '__TMP_SKU_418__' WHERE "Id" = 418;
UPDATE "Products" SET "Sku" = '__TMP_SKU_419__' WHERE "Id" = 419;
UPDATE "Products" SET "Sku" = '__TMP_SKU_420__' WHERE "Id" = 420;
UPDATE "Products" SET "Sku" = '__TMP_SKU_421__' WHERE "Id" = 421;
UPDATE "Products" SET "Sku" = '__TMP_SKU_422__' WHERE "Id" = 422;
UPDATE "Products" SET "Sku" = '__TMP_SKU_423__' WHERE "Id" = 423;
UPDATE "Products" SET "Sku" = '__TMP_SKU_424__' WHERE "Id" = 424;
UPDATE "Products" SET "Sku" = '__TMP_SKU_425__' WHERE "Id" = 425;
UPDATE "Products" SET "Sku" = '__TMP_SKU_426__' WHERE "Id" = 426;
UPDATE "Products" SET "Sku" = '__TMP_SKU_427__' WHERE "Id" = 427;
UPDATE "Products" SET "Sku" = '__TMP_SKU_428__' WHERE "Id" = 428;
UPDATE "Products" SET "Sku" = '__TMP_SKU_429__' WHERE "Id" = 429;
UPDATE "Products" SET "Sku" = '__TMP_SKU_430__' WHERE "Id" = 430;
UPDATE "Products" SET "Sku" = '__TMP_SKU_431__' WHERE "Id" = 431;
UPDATE "Products" SET "Sku" = '__TMP_SKU_432__' WHERE "Id" = 432;
UPDATE "Products" SET "Sku" = '__TMP_SKU_433__' WHERE "Id" = 433;
UPDATE "Products" SET "Sku" = '__TMP_SKU_434__' WHERE "Id" = 434;
UPDATE "Products" SET "Sku" = '__TMP_SKU_435__' WHERE "Id" = 435;
UPDATE "Products" SET "Sku" = '__TMP_SKU_436__' WHERE "Id" = 436;
UPDATE "Products" SET "Sku" = '__TMP_SKU_437__' WHERE "Id" = 437;
UPDATE "Products" SET "Sku" = '__TMP_SKU_438__' WHERE "Id" = 438;
UPDATE "Products" SET "Sku" = '__TMP_SKU_439__' WHERE "Id" = 439;
UPDATE "Products" SET "Sku" = '__TMP_SKU_440__' WHERE "Id" = 440;
UPDATE "Products" SET "Sku" = '__TMP_SKU_441__' WHERE "Id" = 441;
UPDATE "Products" SET "Sku" = '__TMP_SKU_442__' WHERE "Id" = 442;
UPDATE "Products" SET "Sku" = '__TMP_SKU_443__' WHERE "Id" = 443;
UPDATE "Products" SET "Sku" = '__TMP_SKU_444__' WHERE "Id" = 444;
UPDATE "Products" SET "Sku" = '__TMP_SKU_445__' WHERE "Id" = 445;
UPDATE "Products" SET "Sku" = '__TMP_SKU_446__' WHERE "Id" = 446;
UPDATE "Products" SET "Sku" = '__TMP_SKU_447__' WHERE "Id" = 447;
UPDATE "Products" SET "Sku" = '__TMP_SKU_448__' WHERE "Id" = 448;
UPDATE "Products" SET "Sku" = '__TMP_SKU_449__' WHERE "Id" = 449;
UPDATE "Products" SET "Sku" = '__TMP_SKU_450__' WHERE "Id" = 450;
UPDATE "Products" SET "Sku" = '__TMP_SKU_451__' WHERE "Id" = 451;
UPDATE "Products" SET "Sku" = '__TMP_SKU_452__' WHERE "Id" = 452;
UPDATE "Products" SET "Sku" = '__TMP_SKU_453__' WHERE "Id" = 453;
UPDATE "Products" SET "Sku" = '__TMP_SKU_454__' WHERE "Id" = 454;
UPDATE "Products" SET "Sku" = '__TMP_SKU_455__' WHERE "Id" = 455;
UPDATE "Products" SET "Sku" = '__TMP_SKU_456__' WHERE "Id" = 456;
UPDATE "Products" SET "Sku" = '__TMP_SKU_457__' WHERE "Id" = 457;
UPDATE "Products" SET "Sku" = '__TMP_SKU_458__' WHERE "Id" = 458;
UPDATE "Products" SET "Sku" = '__TMP_SKU_459__' WHERE "Id" = 459;
UPDATE "Products" SET "Sku" = '__TMP_SKU_460__' WHERE "Id" = 460;
UPDATE "Products" SET "Sku" = '__TMP_SKU_461__' WHERE "Id" = 461;
UPDATE "Products" SET "Sku" = '__TMP_SKU_462__' WHERE "Id" = 462;
UPDATE "Products" SET "Sku" = '__TMP_SKU_463__' WHERE "Id" = 463;
UPDATE "Products" SET "Sku" = '__TMP_SKU_464__' WHERE "Id" = 464;
UPDATE "Products" SET "Sku" = '__TMP_SKU_465__' WHERE "Id" = 465;
UPDATE "Products" SET "Sku" = '__TMP_SKU_466__' WHERE "Id" = 466;
UPDATE "Products" SET "Sku" = '__TMP_SKU_467__' WHERE "Id" = 467;
UPDATE "Products" SET "Sku" = '__TMP_SKU_468__' WHERE "Id" = 468;
UPDATE "Products" SET "Sku" = '__TMP_SKU_469__' WHERE "Id" = 469;
UPDATE "Products" SET "Sku" = '__TMP_SKU_470__' WHERE "Id" = 470;
UPDATE "Products" SET "Sku" = '__TMP_SKU_471__' WHERE "Id" = 471;
UPDATE "Products" SET "Sku" = '__TMP_SKU_472__' WHERE "Id" = 472;
UPDATE "Products" SET "Sku" = '__TMP_SKU_473__' WHERE "Id" = 473;
UPDATE "Products" SET "Sku" = '__TMP_SKU_474__' WHERE "Id" = 474;
UPDATE "Products" SET "Sku" = '__TMP_SKU_475__' WHERE "Id" = 475;
UPDATE "Products" SET "Sku" = '__TMP_SKU_476__' WHERE "Id" = 476;
UPDATE "Products" SET "Sku" = '__TMP_SKU_477__' WHERE "Id" = 477;
UPDATE "Products" SET "Sku" = '__TMP_SKU_478__' WHERE "Id" = 478;
UPDATE "Products" SET "Sku" = '__TMP_SKU_479__' WHERE "Id" = 479;
UPDATE "Products" SET "Sku" = '__TMP_SKU_480__' WHERE "Id" = 480;
UPDATE "Products" SET "Sku" = '__TMP_SKU_481__' WHERE "Id" = 481;
UPDATE "Products" SET "Sku" = '__TMP_SKU_482__' WHERE "Id" = 482;
UPDATE "Products" SET "Sku" = '__TMP_SKU_483__' WHERE "Id" = 483;
UPDATE "Products" SET "Sku" = '__TMP_SKU_484__' WHERE "Id" = 484;
UPDATE "Products" SET "Sku" = '__TMP_SKU_485__' WHERE "Id" = 485;
UPDATE "Products" SET "Sku" = '__TMP_SKU_486__' WHERE "Id" = 486;
UPDATE "Products" SET "Sku" = '__TMP_SKU_487__' WHERE "Id" = 487;
UPDATE "Products" SET "Sku" = '__TMP_SKU_488__' WHERE "Id" = 488;
UPDATE "Products" SET "Sku" = '__TMP_SKU_489__' WHERE "Id" = 489;
UPDATE "Products" SET "Sku" = '__TMP_SKU_490__' WHERE "Id" = 490;
UPDATE "Products" SET "Sku" = '__TMP_SKU_491__' WHERE "Id" = 491;
UPDATE "Products" SET "Sku" = '__TMP_SKU_492__' WHERE "Id" = 492;
UPDATE "Products" SET "Sku" = '__TMP_SKU_493__' WHERE "Id" = 493;
UPDATE "Products" SET "Sku" = '__TMP_SKU_494__' WHERE "Id" = 494;
UPDATE "Products" SET "Sku" = '__TMP_SKU_495__' WHERE "Id" = 495;
UPDATE "Products" SET "Sku" = '__TMP_SKU_496__' WHERE "Id" = 496;
UPDATE "Products" SET "Sku" = '__TMP_SKU_497__' WHERE "Id" = 497;
UPDATE "Products" SET "Sku" = '__TMP_SKU_498__' WHERE "Id" = 498;
UPDATE "Products" SET "Sku" = '__TMP_SKU_499__' WHERE "Id" = 499;
UPDATE "Products" SET "Sku" = '__TMP_SKU_500__' WHERE "Id" = 500;
UPDATE "Products" SET "Sku" = '__TMP_SKU_501__' WHERE "Id" = 501;
UPDATE "Products" SET "Sku" = '__TMP_SKU_502__' WHERE "Id" = 502;
UPDATE "Products" SET "Sku" = '__TMP_SKU_503__' WHERE "Id" = 503;
UPDATE "Products" SET "Sku" = '__TMP_SKU_504__' WHERE "Id" = 504;
UPDATE "Products" SET "Sku" = '__TMP_SKU_505__' WHERE "Id" = 505;
UPDATE "Products" SET "Sku" = '__TMP_SKU_506__' WHERE "Id" = 506;
UPDATE "Products" SET "Sku" = '__TMP_SKU_507__' WHERE "Id" = 507;
UPDATE "Products" SET "Sku" = '__TMP_SKU_508__' WHERE "Id" = 508;
UPDATE "Products" SET "Sku" = '__TMP_SKU_509__' WHERE "Id" = 509;
UPDATE "Products" SET "Sku" = '__TMP_SKU_510__' WHERE "Id" = 510;
UPDATE "Products" SET "Sku" = '__TMP_SKU_511__' WHERE "Id" = 511;
UPDATE "Products" SET "Sku" = '__TMP_SKU_512__' WHERE "Id" = 512;
UPDATE "Products" SET "Sku" = '__TMP_SKU_513__' WHERE "Id" = 513;
UPDATE "Products" SET "Sku" = '__TMP_SKU_514__' WHERE "Id" = 514;
UPDATE "Products" SET "Sku" = '__TMP_SKU_515__' WHERE "Id" = 515;
UPDATE "Products" SET "Sku" = '__TMP_SKU_516__' WHERE "Id" = 516;
UPDATE "Products" SET "Sku" = '__TMP_SKU_517__' WHERE "Id" = 517;
UPDATE "Products" SET "Sku" = '__TMP_SKU_518__' WHERE "Id" = 518;
UPDATE "Products" SET "Sku" = '__TMP_SKU_519__' WHERE "Id" = 519;
UPDATE "Products" SET "Sku" = '__TMP_SKU_520__' WHERE "Id" = 520;
UPDATE "Products" SET "Sku" = '__TMP_SKU_521__' WHERE "Id" = 521;
UPDATE "Products" SET "Sku" = '__TMP_SKU_522__' WHERE "Id" = 522;
UPDATE "Products" SET "Sku" = '__TMP_SKU_523__' WHERE "Id" = 523;
UPDATE "Products" SET "Sku" = '__TMP_SKU_524__' WHERE "Id" = 524;
UPDATE "Products" SET "Sku" = '__TMP_SKU_525__' WHERE "Id" = 525;
UPDATE "Products" SET "Sku" = '__TMP_SKU_526__' WHERE "Id" = 526;
UPDATE "Products" SET "Sku" = '__TMP_SKU_527__' WHERE "Id" = 527;
UPDATE "Products" SET "Sku" = '__TMP_SKU_528__' WHERE "Id" = 528;
UPDATE "Products" SET "Sku" = '__TMP_SKU_529__' WHERE "Id" = 529;
UPDATE "Products" SET "Sku" = '__TMP_SKU_530__' WHERE "Id" = 530;
UPDATE "Products" SET "Sku" = '__TMP_SKU_531__' WHERE "Id" = 531;
UPDATE "Products" SET "Sku" = '__TMP_SKU_532__' WHERE "Id" = 532;
UPDATE "Products" SET "Sku" = '__TMP_SKU_533__' WHERE "Id" = 533;
UPDATE "Products" SET "Sku" = '__TMP_SKU_534__' WHERE "Id" = 534;
UPDATE "Products" SET "Sku" = '__TMP_SKU_535__' WHERE "Id" = 535;
UPDATE "Products" SET "Sku" = '__TMP_SKU_536__' WHERE "Id" = 536;
UPDATE "Products" SET "Sku" = '__TMP_SKU_537__' WHERE "Id" = 537;
UPDATE "Products" SET "Sku" = '__TMP_SKU_538__' WHERE "Id" = 538;
UPDATE "Products" SET "Sku" = '__TMP_SKU_539__' WHERE "Id" = 539;
UPDATE "Products" SET "Sku" = '__TMP_SKU_540__' WHERE "Id" = 540;
UPDATE "Products" SET "Sku" = '__TMP_SKU_541__' WHERE "Id" = 541;
UPDATE "Products" SET "Sku" = '__TMP_SKU_542__' WHERE "Id" = 542;
UPDATE "Products" SET "Sku" = '__TMP_SKU_543__' WHERE "Id" = 543;
UPDATE "Products" SET "Sku" = '__TMP_SKU_544__' WHERE "Id" = 544;
UPDATE "Products" SET "Sku" = '__TMP_SKU_545__' WHERE "Id" = 545;
UPDATE "Products" SET "Sku" = '__TMP_SKU_546__' WHERE "Id" = 546;
UPDATE "Products" SET "Sku" = '__TMP_SKU_547__' WHERE "Id" = 547;
UPDATE "Products" SET "Sku" = '__TMP_SKU_548__' WHERE "Id" = 548;

-- Bước 2: Cập nhật SKU chính thức theo từng Nhà cung cấp và STT

-- >>> Nhà cung cấp: Hoàng Hà (Prefix: HH)
UPDATE "Products" SET "Sku" = 'HH001', "UpdatedAt" = NOW() WHERE "Id" = 2; -- Cũ: LP10,104
UPDATE "Products" SET "Sku" = 'HH002', "UpdatedAt" = NOW() WHERE "Id" = 3; -- Cũ: LP10,112
UPDATE "Products" SET "Sku" = 'HH003', "UpdatedAt" = NOW() WHERE "Id" = 4; -- Cũ: LP10,113
UPDATE "Products" SET "Sku" = 'HH004', "UpdatedAt" = NOW() WHERE "Id" = 5; -- Cũ: LP10,114
UPDATE "Products" SET "Sku" = 'HH005', "UpdatedAt" = NOW() WHERE "Id" = 6; -- Cũ: LP18,112 -A2
UPDATE "Products" SET "Sku" = 'HH006', "UpdatedAt" = NOW() WHERE "Id" = 7; -- Cũ: LP18,114 -A2
UPDATE "Products" SET "Sku" = 'HH007', "UpdatedAt" = NOW() WHERE "Id" = 8; -- Cũ: LP18,113 - A2
UPDATE "Products" SET "Sku" = 'HH008', "UpdatedAt" = NOW() WHERE "Id" = 9; -- Cũ: LX8003
UPDATE "Products" SET "Sku" = 'HH009', "UpdatedAt" = NOW() WHERE "Id" = 10; -- Cũ: LX8004
UPDATE "Products" SET "Sku" = 'HH010', "UpdatedAt" = NOW() WHERE "Id" = 11; -- Cũ: LP18,112 A1
UPDATE "Products" SET "Sku" = 'HH011', "UpdatedAt" = NOW() WHERE "Id" = 12; -- Cũ: LP18,113 A1
UPDATE "Products" SET "Sku" = 'HH012', "UpdatedAt" = NOW() WHERE "Id" = 13; -- Cũ: LP18,114 A1
UPDATE "Products" SET "Sku" = 'HH013', "UpdatedAt" = NOW() WHERE "Id" = 14; -- Cũ: LX8001
UPDATE "Products" SET "Sku" = 'HH014', "UpdatedAt" = NOW() WHERE "Id" = 15; -- Cũ: LX8002 a2
UPDATE "Products" SET "Sku" = 'HH015', "UpdatedAt" = NOW() WHERE "Id" = 16; -- Cũ: LX8002
UPDATE "Products" SET "Sku" = 'HH016', "UpdatedAt" = NOW() WHERE "Id" = 17; -- Cũ: LX8005- A2
UPDATE "Products" SET "Sku" = 'HH017', "UpdatedAt" = NOW() WHERE "Id" = 18; -- Cũ: LP18101
UPDATE "Products" SET "Sku" = 'HH018', "UpdatedAt" = NOW() WHERE "Id" = 19; -- Cũ: LX8009 - A2
UPDATE "Products" SET "Sku" = 'HH019', "UpdatedAt" = NOW() WHERE "Id" = 20; -- Cũ: LX8009
UPDATE "Products" SET "Sku" = 'HH020', "UpdatedAt" = NOW() WHERE "Id" = 21; -- Cũ: LX8010
UPDATE "Products" SET "Sku" = 'HH021', "UpdatedAt" = NOW() WHERE "Id" = 22; -- Cũ: LX8014
UPDATE "Products" SET "Sku" = 'HH022', "UpdatedAt" = NOW() WHERE "Id" = 23; -- Cũ: LX8016 - A2
UPDATE "Products" SET "Sku" = 'HH023', "UpdatedAt" = NOW() WHERE "Id" = 24; -- Cũ: LX8017
UPDATE "Products" SET "Sku" = 'HH024', "UpdatedAt" = NOW() WHERE "Id" = 25; -- Cũ: LX8012
UPDATE "Products" SET "Sku" = 'HH025', "UpdatedAt" = NOW() WHERE "Id" = 26; -- Cũ: LX8005
UPDATE "Products" SET "Sku" = 'HH026', "UpdatedAt" = NOW() WHERE "Id" = 27; -- Cũ: LX8014 -A2
UPDATE "Products" SET "Sku" = 'HH027', "UpdatedAt" = NOW() WHERE "Id" = 28; -- Cũ: LX8017 a2
UPDATE "Products" SET "Sku" = 'HH028', "UpdatedAt" = NOW() WHERE "Id" = 29; -- Cũ: LX8016
UPDATE "Products" SET "Sku" = 'HH029', "UpdatedAt" = NOW() WHERE "Id" = 30; -- Cũ: LP18101 A2
UPDATE "Products" SET "Sku" = 'HH030', "UpdatedAt" = NOW() WHERE "Id" = 31; -- Cũ: LP18102
UPDATE "Products" SET "Sku" = 'HH031', "UpdatedAt" = NOW() WHERE "Id" = 32; -- Cũ: LP18104 A2
UPDATE "Products" SET "Sku" = 'HH032', "UpdatedAt" = NOW() WHERE "Id" = 33; -- Cũ: LP18.8018 A1
UPDATE "Products" SET "Sku" = 'HH033', "UpdatedAt" = NOW() WHERE "Id" = 34; -- Cũ: LP18102 A2
UPDATE "Products" SET "Sku" = 'HH034', "UpdatedAt" = NOW() WHERE "Id" = 35; -- Cũ: LP18103
UPDATE "Products" SET "Sku" = 'HH035', "UpdatedAt" = NOW() WHERE "Id" = 36; -- Cũ: LP18.8021 A1
UPDATE "Products" SET "Sku" = 'HH036', "UpdatedAt" = NOW() WHERE "Id" = 37; -- Cũ: LP18.8003 A2
UPDATE "Products" SET "Sku" = 'HH037', "UpdatedAt" = NOW() WHERE "Id" = 38; -- Cũ: LP18.8003 A1
UPDATE "Products" SET "Sku" = 'HH038', "UpdatedAt" = NOW() WHERE "Id" = 39; -- Cũ: LX6610
UPDATE "Products" SET "Sku" = 'HH039', "UpdatedAt" = NOW() WHERE "Id" = 40; -- Cũ: LP18.8016 A1
UPDATE "Products" SET "Sku" = 'HH040', "UpdatedAt" = NOW() WHERE "Id" = 41; -- Cũ: LX6007
UPDATE "Products" SET "Sku" = 'HH041', "UpdatedAt" = NOW() WHERE "Id" = 42; -- Cũ: LX6001
UPDATE "Products" SET "Sku" = 'HH042', "UpdatedAt" = NOW() WHERE "Id" = 43; -- Cũ: LX6609
UPDATE "Products" SET "Sku" = 'HH043', "UpdatedAt" = NOW() WHERE "Id" = 44; -- Cũ: LP18104
UPDATE "Products" SET "Sku" = 'HH044', "UpdatedAt" = NOW() WHERE "Id" = 45; -- Cũ: LP18103 A2
UPDATE "Products" SET "Sku" = 'HH045', "UpdatedAt" = NOW() WHERE "Id" = 46; -- Cũ: LX6602
UPDATE "Products" SET "Sku" = 'HH046', "UpdatedAt" = NOW() WHERE "Id" = 47; -- Cũ: LP96-6603 A2
UPDATE "Products" SET "Sku" = 'HH047', "UpdatedAt" = NOW() WHERE "Id" = 48; -- Cũ: LP96103 A2
UPDATE "Products" SET "Sku" = 'HH048', "UpdatedAt" = NOW() WHERE "Id" = 49; -- Cũ: LP96104
UPDATE "Products" SET "Sku" = 'HH049', "UpdatedAt" = NOW() WHERE "Id" = 50; -- Cũ: LP96103
UPDATE "Products" SET "Sku" = 'HH050', "UpdatedAt" = NOW() WHERE "Id" = 51; -- Cũ: LXC6105
UPDATE "Products" SET "Sku" = 'HH051', "UpdatedAt" = NOW() WHERE "Id" = 52; -- Cũ: LX6621
UPDATE "Products" SET "Sku" = 'HH052', "UpdatedAt" = NOW() WHERE "Id" = 53; -- Cũ: LP96102 A2
UPDATE "Products" SET "Sku" = 'HH053', "UpdatedAt" = NOW() WHERE "Id" = 54; -- Cũ: LX6618
UPDATE "Products" SET "Sku" = 'HH054', "UpdatedAt" = NOW() WHERE "Id" = 55; -- Cũ: LP96101
UPDATE "Products" SET "Sku" = 'HH055', "UpdatedAt" = NOW() WHERE "Id" = 56; -- Cũ: LX6617
UPDATE "Products" SET "Sku" = 'HH056', "UpdatedAt" = NOW() WHERE "Id" = 57; -- Cũ: LX6616
UPDATE "Products" SET "Sku" = 'HH057', "UpdatedAt" = NOW() WHERE "Id" = 58; -- Cũ: LX6614 A2
UPDATE "Products" SET "Sku" = 'HH058', "UpdatedAt" = NOW() WHERE "Id" = 59; -- Cũ: LP96-6603
UPDATE "Products" SET "Sku" = 'HH059', "UpdatedAt" = NOW() WHERE "Id" = 60; -- Cũ: LX6614
UPDATE "Products" SET "Sku" = 'HH060', "UpdatedAt" = NOW() WHERE "Id" = 61; -- Cũ: LP96102
UPDATE "Products" SET "Sku" = 'HH061', "UpdatedAt" = NOW() WHERE "Id" = 62; -- Cũ: LXC6117
UPDATE "Products" SET "Sku" = 'HH062', "UpdatedAt" = NOW() WHERE "Id" = 63; -- Cũ: LXC6112-h11
UPDATE "Products" SET "Sku" = 'HH063', "UpdatedAt" = NOW() WHERE "Id" = 64; -- Cũ: LV48000 A2
UPDATE "Products" SET "Sku" = 'HH064', "UpdatedAt" = NOW() WHERE "Id" = 65; -- Cũ: LXC6110 H4
UPDATE "Products" SET "Sku" = 'HH065', "UpdatedAt" = NOW() WHERE "Id" = 66; -- Cũ: LXC6118
UPDATE "Products" SET "Sku" = 'HH066', "UpdatedAt" = NOW() WHERE "Id" = 67; -- Cũ: LXC6114
UPDATE "Products" SET "Sku" = 'HH067', "UpdatedAt" = NOW() WHERE "Id" = 68; -- Cũ: LX4863
UPDATE "Products" SET "Sku" = 'HH068', "UpdatedAt" = NOW() WHERE "Id" = 69; -- Cũ: LXC6116
UPDATE "Products" SET "Sku" = 'HH069', "UpdatedAt" = NOW() WHERE "Id" = 70; -- Cũ: LV4851
UPDATE "Products" SET "Sku" = 'HH070', "UpdatedAt" = NOW() WHERE "Id" = 71; -- Cũ: LXC6119
UPDATE "Products" SET "Sku" = 'HH071', "UpdatedAt" = NOW() WHERE "Id" = 72; -- Cũ: LV4850
UPDATE "Products" SET "Sku" = 'HH072', "UpdatedAt" = NOW() WHERE "Id" = 73; -- Cũ: LV4850 A2
UPDATE "Products" SET "Sku" = 'HH073', "UpdatedAt" = NOW() WHERE "Id" = 74; -- Cũ: LXC6115
UPDATE "Products" SET "Sku" = 'HH074', "UpdatedAt" = NOW() WHERE "Id" = 75; -- Cũ: LX4861
UPDATE "Products" SET "Sku" = 'HH075', "UpdatedAt" = NOW() WHERE "Id" = 76; -- Cũ: LX4862
UPDATE "Products" SET "Sku" = 'HH076', "UpdatedAt" = NOW() WHERE "Id" = 77; -- Cũ: LP948.154- ĐIỂM
UPDATE "Products" SET "Sku" = 'HH077', "UpdatedAt" = NOW() WHERE "Id" = 78; -- Cũ: LP948.150- ĐIỂM
UPDATE "Products" SET "Sku" = 'HH078', "UpdatedAt" = NOW() WHERE "Id" = 79; -- Cũ: LXP3602
UPDATE "Products" SET "Sku" = 'HH079', "UpdatedAt" = NOW() WHERE "Id" = 80; -- Cũ: LX4865
UPDATE "Products" SET "Sku" = 'HH080', "UpdatedAt" = NOW() WHERE "Id" = 81; -- Cũ: LX4867
UPDATE "Products" SET "Sku" = 'HH081', "UpdatedAt" = NOW() WHERE "Id" = 82; -- Cũ: LXP3603
UPDATE "Products" SET "Sku" = 'HH082', "UpdatedAt" = NOW() WHERE "Id" = 83; -- Cũ: LXP3601-ĐIỂM a2
UPDATE "Products" SET "Sku" = 'HH083', "UpdatedAt" = NOW() WHERE "Id" = 84; -- Cũ: LP948.156
UPDATE "Products" SET "Sku" = 'HH084', "UpdatedAt" = NOW() WHERE "Id" = 85; -- Cũ: LP948.155
UPDATE "Products" SET "Sku" = 'HH085', "UpdatedAt" = NOW() WHERE "Id" = 86; -- Cũ: LX4864- ĐIỂM
UPDATE "Products" SET "Sku" = 'HH086', "UpdatedAt" = NOW() WHERE "Id" = 87; -- Cũ: LP948.157
UPDATE "Products" SET "Sku" = 'HH087', "UpdatedAt" = NOW() WHERE "Id" = 88; -- Cũ: LP948.150
UPDATE "Products" SET "Sku" = 'HH088', "UpdatedAt" = NOW() WHERE "Id" = 89; -- Cũ: LXP3601
UPDATE "Products" SET "Sku" = 'HH089', "UpdatedAt" = NOW() WHERE "Id" = 90; -- Cũ: LP948.156-ĐIỂM
UPDATE "Products" SET "Sku" = 'HH090', "UpdatedAt" = NOW() WHERE "Id" = 91; -- Cũ: LP948.154
UPDATE "Products" SET "Sku" = 'HH091', "UpdatedAt" = NOW() WHERE "Id" = 92; -- Cũ: LP936.133
UPDATE "Products" SET "Sku" = 'HH092', "UpdatedAt" = NOW() WHERE "Id" = 93; -- Cũ: LP936.132-ĐIỂM
UPDATE "Products" SET "Sku" = 'HH093', "UpdatedAt" = NOW() WHERE "Id" = 94; -- Cũ: LP936.132
UPDATE "Products" SET "Sku" = 'HH094', "UpdatedAt" = NOW() WHERE "Id" = 95; -- Cũ: LXP3606-ĐIỂM
UPDATE "Products" SET "Sku" = 'HH095', "UpdatedAt" = NOW() WHERE "Id" = 96; -- Cũ: LXP3606
UPDATE "Products" SET "Sku" = 'HH096', "UpdatedAt" = NOW() WHERE "Id" = 97; -- Cũ: LXP3602-ĐIỂM
UPDATE "Products" SET "Sku" = 'HH097', "UpdatedAt" = NOW() WHERE "Id" = 98; -- Cũ: LP936.131-KHÓI TRẮNG
UPDATE "Products" SET "Sku" = 'HH098', "UpdatedAt" = NOW() WHERE "Id" = 99; -- Cũ: LXP3607
UPDATE "Products" SET "Sku" = 'HH099', "UpdatedAt" = NOW() WHERE "Id" = 100; -- Cũ: LP936.134
UPDATE "Products" SET "Sku" = 'HH100', "UpdatedAt" = NOW() WHERE "Id" = 101; -- Cũ: LV3600
UPDATE "Products" SET "Sku" = 'HH101', "UpdatedAt" = NOW() WHERE "Id" = 102; -- Cũ: LX36000
UPDATE "Products" SET "Sku" = 'HH102', "UpdatedAt" = NOW() WHERE "Id" = 103; -- Cũ: LP936.135
UPDATE "Products" SET "Sku" = 'HH103', "UpdatedAt" = NOW() WHERE "Id" = 104; -- Cũ: LP936.134-ĐIỂM
UPDATE "Products" SET "Sku" = 'HH104', "UpdatedAt" = NOW() WHERE "Id" = 105; -- Cũ: LV3652--h13
UPDATE "Products" SET "Sku" = 'HH105', "UpdatedAt" = NOW() WHERE "Id" = 106; -- Cũ: LX36601
UPDATE "Products" SET "Sku" = 'HH106', "UpdatedAt" = NOW() WHERE "Id" = 107; -- Cũ: LXK3606T
UPDATE "Products" SET "Sku" = 'HH107', "UpdatedAt" = NOW() WHERE "Id" = 108; -- Cũ: LX3601-T
UPDATE "Products" SET "Sku" = 'HH108', "UpdatedAt" = NOW() WHERE "Id" = 109; -- Cũ: LV3658
UPDATE "Products" SET "Sku" = 'HH109', "UpdatedAt" = NOW() WHERE "Id" = 110; -- Cũ: LXK3607T
UPDATE "Products" SET "Sku" = 'HH110', "UpdatedAt" = NOW() WHERE "Id" = 111; -- Cũ: LX3637
UPDATE "Products" SET "Sku" = 'HH111', "UpdatedAt" = NOW() WHERE "Id" = 112; -- Cũ: LXK3608T
UPDATE "Products" SET "Sku" = 'HH112', "UpdatedAt" = NOW() WHERE "Id" = 113; -- Cũ: LX3636
UPDATE "Products" SET "Sku" = 'HH113', "UpdatedAt" = NOW() WHERE "Id" = 114; -- Cũ: LX3635
UPDATE "Products" SET "Sku" = 'HH114', "UpdatedAt" = NOW() WHERE "Id" = 115; -- Cũ: LV3650
UPDATE "Products" SET "Sku" = 'HH115', "UpdatedAt" = NOW() WHERE "Id" = 116; -- Cũ: LX3634-ĐIỂM
UPDATE "Products" SET "Sku" = 'HH116', "UpdatedAt" = NOW() WHERE "Id" = 117; -- Cũ: LX3603-T
UPDATE "Products" SET "Sku" = 'HH117', "UpdatedAt" = NOW() WHERE "Id" = 118; -- Cũ: LX3604-T
UPDATE "Products" SET "Sku" = 'HH118', "UpdatedAt" = NOW() WHERE "Id" = 119; -- Cũ: LX3634
UPDATE "Products" SET "Sku" = 'HH119', "UpdatedAt" = NOW() WHERE "Id" = 120; -- Cũ: LX3602-T
UPDATE "Products" SET "Sku" = 'HH120', "UpdatedAt" = NOW() WHERE "Id" = 121; -- Cũ: LXK3605T
UPDATE "Products" SET "Sku" = 'HH121', "UpdatedAt" = NOW() WHERE "Id" = 122; -- Cũ: LX3659
UPDATE "Products" SET "Sku" = 'HH122', "UpdatedAt" = NOW() WHERE "Id" = 123; -- Cũ: LX3666
UPDATE "Products" SET "Sku" = 'HH123', "UpdatedAt" = NOW() WHERE "Id" = 124; -- Cũ: LX3664
UPDATE "Products" SET "Sku" = 'HH124', "UpdatedAt" = NOW() WHERE "Id" = 125; -- Cũ: LX3638
UPDATE "Products" SET "Sku" = 'HH125', "UpdatedAt" = NOW() WHERE "Id" = 126; -- Cũ: LX3638-ĐIỂM
UPDATE "Products" SET "Sku" = 'HH126', "UpdatedAt" = NOW() WHERE "Id" = 127; -- Cũ: LX3658
UPDATE "Products" SET "Sku" = 'HH127', "UpdatedAt" = NOW() WHERE "Id" = 128; -- Cũ: LX3662-ĐIỂM
UPDATE "Products" SET "Sku" = 'HH128', "UpdatedAt" = NOW() WHERE "Id" = 129; -- Cũ: LX3662
UPDATE "Products" SET "Sku" = 'HH129', "UpdatedAt" = NOW() WHERE "Id" = 130; -- Cũ: LX3663
UPDATE "Products" SET "Sku" = 'HH130', "UpdatedAt" = NOW() WHERE "Id" = 131; -- Cũ: LX3658 -ĐIỂM
UPDATE "Products" SET "Sku" = 'HH131', "UpdatedAt" = NOW() WHERE "Id" = 132; -- Cũ: LX3636-ĐIỂM
UPDATE "Products" SET "Sku" = 'HH132', "UpdatedAt" = NOW() WHERE "Id" = 133; -- Cũ: LX3665
UPDATE "Products" SET "Sku" = 'HH133', "UpdatedAt" = NOW() WHERE "Id" = 134; -- Cũ: LX3664-ĐIỂM
UPDATE "Products" SET "Sku" = 'HH134', "UpdatedAt" = NOW() WHERE "Id" = 135; -- Cũ: LX3639
UPDATE "Products" SET "Sku" = 'HH135', "UpdatedAt" = NOW() WHERE "Id" = 136; -- Cũ: LX3667
UPDATE "Products" SET "Sku" = 'HH136', "UpdatedAt" = NOW() WHERE "Id" = 137; -- Cũ: LXM3672-ĐIỂM
UPDATE "Products" SET "Sku" = 'HH137', "UpdatedAt" = NOW() WHERE "Id" = 138; -- Cũ: LX3686
UPDATE "Products" SET "Sku" = 'HH138', "UpdatedAt" = NOW() WHERE "Id" = 139; -- Cũ: LXM3671
UPDATE "Products" SET "Sku" = 'HH139', "UpdatedAt" = NOW() WHERE "Id" = 140; -- Cũ: LXM3672
UPDATE "Products" SET "Sku" = 'HH140', "UpdatedAt" = NOW() WHERE "Id" = 141; -- Cũ: LX3669
UPDATE "Products" SET "Sku" = 'HH141', "UpdatedAt" = NOW() WHERE "Id" = 142; -- Cũ: LX3668-ĐIỂM
UPDATE "Products" SET "Sku" = 'HH142', "UpdatedAt" = NOW() WHERE "Id" = 143; -- Cũ: LXM3670
UPDATE "Products" SET "Sku" = 'HH143', "UpdatedAt" = NOW() WHERE "Id" = 144; -- Cũ: LXM3670-ĐIỂM
UPDATE "Products" SET "Sku" = 'HH144', "UpdatedAt" = NOW() WHERE "Id" = 145; -- Cũ: LX3668
UPDATE "Products" SET "Sku" = 'HH145', "UpdatedAt" = NOW() WHERE "Id" = 146; -- Cũ: LX3688
UPDATE "Products" SET "Sku" = 'HH146', "UpdatedAt" = NOW() WHERE "Id" = 147; -- Cũ: LXM3673
UPDATE "Products" SET "Sku" = 'HH147', "UpdatedAt" = NOW() WHERE "Id" = 148; -- Cũ: LX3687
UPDATE "Products" SET "Sku" = 'HH148', "UpdatedAt" = NOW() WHERE "Id" = 149; -- Cũ: LX3666-ĐIỂM
UPDATE "Products" SET "Sku" = 'HH149', "UpdatedAt" = NOW() WHERE "Id" = 150; -- Cũ: LX3686 ĐIỂM
UPDATE "Products" SET "Sku" = 'HH150', "UpdatedAt" = NOW() WHERE "Id" = 151; -- Cũ: LX3689
UPDATE "Products" SET "Sku" = 'HH151', "UpdatedAt" = NOW() WHERE "Id" = 152; -- Cũ: LX3691
UPDATE "Products" SET "Sku" = 'HH152', "UpdatedAt" = NOW() WHERE "Id" = 153; -- Cũ: LX3688 ĐIỂM
UPDATE "Products" SET "Sku" = 'HH153', "UpdatedAt" = NOW() WHERE "Id" = 154; -- Cũ: LX3617
UPDATE "Products" SET "Sku" = 'HH154', "UpdatedAt" = NOW() WHERE "Id" = 155; -- Cũ: LX3802
UPDATE "Products" SET "Sku" = 'HH155', "UpdatedAt" = NOW() WHERE "Id" = 156; -- Cũ: LX3690
UPDATE "Products" SET "Sku" = 'HH156', "UpdatedAt" = NOW() WHERE "Id" = 157; -- Cũ: LX367
UPDATE "Products" SET "Sku" = 'HH157', "UpdatedAt" = NOW() WHERE "Id" = 158; -- Cũ: LX335
UPDATE "Products" SET "Sku" = 'HH158', "UpdatedAt" = NOW() WHERE "Id" = 159; -- Cũ: LX337
UPDATE "Products" SET "Sku" = 'HH159', "UpdatedAt" = NOW() WHERE "Id" = 160; -- Cũ: LX3690 ĐIỂM
UPDATE "Products" SET "Sku" = 'HH160', "UpdatedAt" = NOW() WHERE "Id" = 161; -- Cũ: LX3622
UPDATE "Products" SET "Sku" = 'HH161', "UpdatedAt" = NOW() WHERE "Id" = 162; -- Cũ: LX3629
UPDATE "Products" SET "Sku" = 'HH162', "UpdatedAt" = NOW() WHERE "Id" = 163; -- Cũ: LX369
UPDATE "Products" SET "Sku" = 'HH163', "UpdatedAt" = NOW() WHERE "Id" = 164; -- Cũ: LK303
UPDATE "Products" SET "Sku" = 'HH164', "UpdatedAt" = NOW() WHERE "Id" = 165; -- Cũ: LXP303
UPDATE "Products" SET "Sku" = 'HH165', "UpdatedAt" = NOW() WHERE "Id" = 166; -- Cũ: LX3133
UPDATE "Products" SET "Sku" = 'HH166', "UpdatedAt" = NOW() WHERE "Id" = 167; -- Cũ: LX5525
UPDATE "Products" SET "Sku" = 'HH167', "UpdatedAt" = NOW() WHERE "Id" = 168; -- Cũ: LX5516
UPDATE "Products" SET "Sku" = 'HH168', "UpdatedAt" = NOW() WHERE "Id" = 169; -- Cũ: NH5604
UPDATE "Products" SET "Sku" = 'HH169', "UpdatedAt" = NOW() WHERE "Id" = 170; -- Cũ: NH5602
UPDATE "Products" SET "Sku" = 'HH170', "UpdatedAt" = NOW() WHERE "Id" = 171; -- Cũ: NH5601
UPDATE "Products" SET "Sku" = 'HH171', "UpdatedAt" = NOW() WHERE "Id" = 172; -- Cũ: LX5524
UPDATE "Products" SET "Sku" = 'HH172', "UpdatedAt" = NOW() WHERE "Id" = 173; -- Cũ: LX5521
UPDATE "Products" SET "Sku" = 'HH173', "UpdatedAt" = NOW() WHERE "Id" = 174; -- Cũ: LX5525 A2
UPDATE "Products" SET "Sku" = 'HH174', "UpdatedAt" = NOW() WHERE "Id" = 175; -- Cũ: NH5605
UPDATE "Products" SET "Sku" = 'HH175', "UpdatedAt" = NOW() WHERE "Id" = 176; -- Cũ: LX5516 A2
UPDATE "Products" SET "Sku" = 'HH176', "UpdatedAt" = NOW() WHERE "Id" = 177; -- Cũ: NH5604 A2
UPDATE "Products" SET "Sku" = 'HH177', "UpdatedAt" = NOW() WHERE "Id" = 178; -- Cũ: NH5603
UPDATE "Products" SET "Sku" = 'HH178', "UpdatedAt" = NOW() WHERE "Id" = 179; -- Cũ: LX5524 A2
UPDATE "Products" SET "Sku" = 'HH179', "UpdatedAt" = NOW() WHERE "Id" = 180; -- Cũ: LK305-h1
UPDATE "Products" SET "Sku" = 'HH180', "UpdatedAt" = NOW() WHERE "Id" = 181; -- Cũ: LX5527
UPDATE "Products" SET "Sku" = 'HH181', "UpdatedAt" = NOW() WHERE "Id" = 182; -- Cũ: LX46002
UPDATE "Products" SET "Sku" = 'HH182', "UpdatedAt" = NOW() WHERE "Id" = 183; -- Cũ: LXK46050
UPDATE "Products" SET "Sku" = 'HH183', "UpdatedAt" = NOW() WHERE "Id" = 184; -- Cũ: LX6905
UPDATE "Products" SET "Sku" = 'HH184', "UpdatedAt" = NOW() WHERE "Id" = 185; -- Cũ: HM5028-MÁT
UPDATE "Products" SET "Sku" = 'HH185', "UpdatedAt" = NOW() WHERE "Id" = 186; -- Cũ: HS514 A1
UPDATE "Products" SET "Sku" = 'HH186', "UpdatedAt" = NOW() WHERE "Id" = 187; -- Cũ: HXK-503 A1
UPDATE "Products" SET "Sku" = 'HH187', "UpdatedAt" = NOW() WHERE "Id" = 188; -- Cũ: LXV6802
UPDATE "Products" SET "Sku" = 'HH188', "UpdatedAt" = NOW() WHERE "Id" = 189; -- Cũ: LX46001
UPDATE "Products" SET "Sku" = 'HH189', "UpdatedAt" = NOW() WHERE "Id" = 190; -- Cũ: LX6903
UPDATE "Products" SET "Sku" = 'HH190', "UpdatedAt" = NOW() WHERE "Id" = 191; -- Cũ: HM5028- MÁT B
UPDATE "Products" SET "Sku" = 'HH191', "UpdatedAt" = NOW() WHERE "Id" = 192; -- Cũ: LXV6806
UPDATE "Products" SET "Sku" = 'HH192', "UpdatedAt" = NOW() WHERE "Id" = 193; -- Cũ: HUS 5018-SUGAR
UPDATE "Products" SET "Sku" = 'HH193', "UpdatedAt" = NOW() WHERE "Id" = 194; -- Cũ: HXK-503 B
UPDATE "Products" SET "Sku" = 'HH194', "UpdatedAt" = NOW() WHERE "Id" = 195; -- Cũ: LXV6801
UPDATE "Products" SET "Sku" = 'HH195', "UpdatedAt" = NOW() WHERE "Id" = 196; -- Cũ: HG5407 A2
UPDATE "Products" SET "Sku" = 'HH196', "UpdatedAt" = NOW() WHERE "Id" = 197; -- Cũ: LXK46054
UPDATE "Products" SET "Sku" = 'HH197', "UpdatedAt" = NOW() WHERE "Id" = 198; -- Cũ: LP 46-123
UPDATE "Products" SET "Sku" = 'HH198', "UpdatedAt" = NOW() WHERE "Id" = 199; -- Cũ: LP 46-120
UPDATE "Products" SET "Sku" = 'HH199', "UpdatedAt" = NOW() WHERE "Id" = 200; -- Cũ: PLX413
UPDATE "Products" SET "Sku" = 'HH200', "UpdatedAt" = NOW() WHERE "Id" = 201; -- Cũ: PLX415
UPDATE "Products" SET "Sku" = 'HH201', "UpdatedAt" = NOW() WHERE "Id" = 202; -- Cũ: LH46006
UPDATE "Products" SET "Sku" = 'HH202', "UpdatedAt" = NOW() WHERE "Id" = 203; -- Cũ: LP 46-122
UPDATE "Products" SET "Sku" = 'HH203', "UpdatedAt" = NOW() WHERE "Id" = 204; -- Cũ: LHK46056
UPDATE "Products" SET "Sku" = 'HH204', "UpdatedAt" = NOW() WHERE "Id" = 205; -- Cũ: LXK46052
UPDATE "Products" SET "Sku" = 'HH205', "UpdatedAt" = NOW() WHERE "Id" = 206; -- Cũ: LH46005
UPDATE "Products" SET "Sku" = 'HH206', "UpdatedAt" = NOW() WHERE "Id" = 207; -- Cũ: LP 46-121
UPDATE "Products" SET "Sku" = 'HH207', "UpdatedAt" = NOW() WHERE "Id" = 208; -- Cũ: LHK46055
UPDATE "Products" SET "Sku" = 'HH208', "UpdatedAt" = NOW() WHERE "Id" = 209; -- Cũ: LH46004
UPDATE "Products" SET "Sku" = 'HH209', "UpdatedAt" = NOW() WHERE "Id" = 210; -- Cũ: LXK46051
UPDATE "Products" SET "Sku" = 'HH210', "UpdatedAt" = NOW() WHERE "Id" = 211; -- Cũ: PLX412
UPDATE "Products" SET "Sku" = 'HH211', "UpdatedAt" = NOW() WHERE "Id" = 212; -- Cũ: PLX5013
UPDATE "Products" SET "Sku" = 'HH212', "UpdatedAt" = NOW() WHERE "Id" = 213; -- Cũ: PLX5011
UPDATE "Products" SET "Sku" = 'HH213', "UpdatedAt" = NOW() WHERE "Id" = 214; -- Cũ: PLX5015
UPDATE "Products" SET "Sku" = 'HH214', "UpdatedAt" = NOW() WHERE "Id" = 215; -- Cũ: PLX5014
UPDATE "Products" SET "Sku" = 'HH215', "UpdatedAt" = NOW() WHERE "Id" = 216; -- Cũ: PLX5015 A2
UPDATE "Products" SET "Sku" = 'HH216', "UpdatedAt" = NOW() WHERE "Id" = 217; -- Cũ: PLX5012

-- >>> Nhà cung cấp: Nice (Prefix: NICE)
UPDATE "Products" SET "Sku" = 'NICE001', "UpdatedAt" = NOW() WHERE "Id" = 218; -- Cũ: 48-6001-Nhạt
UPDATE "Products" SET "Sku" = 'NICE002', "UpdatedAt" = NOW() WHERE "Id" = 219; -- Cũ: 48-6003-Vân
UPDATE "Products" SET "Sku" = 'NICE003', "UpdatedAt" = NOW() WHERE "Id" = 220; -- Cũ: 48-6001-Điểm
UPDATE "Products" SET "Sku" = 'NICE004', "UpdatedAt" = NOW() WHERE "Id" = 221; -- Cũ: 48-6007-Nhạt
UPDATE "Products" SET "Sku" = 'NICE005', "UpdatedAt" = NOW() WHERE "Id" = 222; -- Cũ: 48-6002-Điểm
UPDATE "Products" SET "Sku" = 'NICE006', "UpdatedAt" = NOW() WHERE "Id" = 223; -- Cũ: 036-601-kem vàng
UPDATE "Products" SET "Sku" = 'NICE007', "UpdatedAt" = NOW() WHERE "Id" = 224; -- Cũ: 48-6007-Đậm
UPDATE "Products" SET "Sku" = 'NICE008', "UpdatedAt" = NOW() WHERE "Id" = 225; -- Cũ: 036-6003 nhạt
UPDATE "Products" SET "Sku" = 'NICE009', "UpdatedAt" = NOW() WHERE "Id" = 226; -- Cũ: 036-6002 Nhạt
UPDATE "Products" SET "Sku" = 'NICE010', "UpdatedAt" = NOW() WHERE "Id" = 227; -- Cũ: 48-6007-Điểm
UPDATE "Products" SET "Sku" = 'NICE011', "UpdatedAt" = NOW() WHERE "Id" = 228; -- Cũ: 48-6000- Trắng tinh-53(30.12.23)
UPDATE "Products" SET "Sku" = 'NICE012', "UpdatedAt" = NOW() WHERE "Id" = 229; -- Cũ: 48-5004-Nhạt
UPDATE "Products" SET "Sku" = 'NICE013', "UpdatedAt" = NOW() WHERE "Id" = 230; -- Cũ: 48-6003-Điểm
UPDATE "Products" SET "Sku" = 'NICE014', "UpdatedAt" = NOW() WHERE "Id" = 231; -- Cũ: 48-6001-Đậm
UPDATE "Products" SET "Sku" = 'NICE015', "UpdatedAt" = NOW() WHERE "Id" = 232; -- Cũ: 48-6002-Khói
UPDATE "Products" SET "Sku" = 'NICE016', "UpdatedAt" = NOW() WHERE "Id" = 233; -- Cũ: 5-1002
UPDATE "Products" SET "Sku" = 'NICE017', "UpdatedAt" = NOW() WHERE "Id" = 234; -- Cũ: 5-1602
UPDATE "Products" SET "Sku" = 'NICE018', "UpdatedAt" = NOW() WHERE "Id" = 235; -- Cũ: 5-1323
UPDATE "Products" SET "Sku" = 'NICE019', "UpdatedAt" = NOW() WHERE "Id" = 236; -- Cũ: 5-1004
UPDATE "Products" SET "Sku" = 'NICE020', "UpdatedAt" = NOW() WHERE "Id" = 237; -- Cũ: 5-1501
UPDATE "Products" SET "Sku" = 'NICE021', "UpdatedAt" = NOW() WHERE "Id" = 238; -- Cũ: 5-1601
UPDATE "Products" SET "Sku" = 'NICE022', "UpdatedAt" = NOW() WHERE "Id" = 239; -- Cũ: 5-1603
UPDATE "Products" SET "Sku" = 'NICE023', "UpdatedAt" = NOW() WHERE "Id" = 240; -- Cũ: 48-5004-Đậm
UPDATE "Products" SET "Sku" = 'NICE024', "UpdatedAt" = NOW() WHERE "Id" = 241; -- Cũ: 5-1001
UPDATE "Products" SET "Sku" = 'NICE025', "UpdatedAt" = NOW() WHERE "Id" = 242; -- Cũ: 5-1013
UPDATE "Products" SET "Sku" = 'NICE026', "UpdatedAt" = NOW() WHERE "Id" = 243; -- Cũ: 48-5004-Điểm
UPDATE "Products" SET "Sku" = 'NICE027', "UpdatedAt" = NOW() WHERE "Id" = 244; -- Cũ: 48-01 GO
UPDATE "Products" SET "Sku" = 'NICE028', "UpdatedAt" = NOW() WHERE "Id" = 245; -- Cũ: 48-02 GO
UPDATE "Products" SET "Sku" = 'NICE029', "UpdatedAt" = NOW() WHERE "Id" = 246; -- Cũ: 5-1311
UPDATE "Products" SET "Sku" = 'NICE030', "UpdatedAt" = NOW() WHERE "Id" = 247; -- Cũ: 5-1012
UPDATE "Products" SET "Sku" = 'NICE031', "UpdatedAt" = NOW() WHERE "Id" = 248; -- Cũ: 6-1304-men đường
UPDATE "Products" SET "Sku" = 'NICE032', "UpdatedAt" = NOW() WHERE "Id" = 249; -- Cũ: 6-1019
UPDATE "Products" SET "Sku" = 'NICE033', "UpdatedAt" = NOW() WHERE "Id" = 250; -- Cũ: 6-1022
UPDATE "Products" SET "Sku" = 'NICE034', "UpdatedAt" = NOW() WHERE "Id" = 251; -- Cũ: 6-6001
UPDATE "Products" SET "Sku" = 'NICE035', "UpdatedAt" = NOW() WHERE "Id" = 252; -- Cũ: 6-1020
UPDATE "Products" SET "Sku" = 'NICE036', "UpdatedAt" = NOW() WHERE "Id" = 253; -- Cũ: 5-1312
UPDATE "Products" SET "Sku" = 'NICE037', "UpdatedAt" = NOW() WHERE "Id" = 254; -- Cũ: 6-6007
UPDATE "Products" SET "Sku" = 'NICE038', "UpdatedAt" = NOW() WHERE "Id" = 255; -- Cũ: 6-6022
UPDATE "Products" SET "Sku" = 'NICE039', "UpdatedAt" = NOW() WHERE "Id" = 256; -- Cũ: 6-1501- Gỗ mát
UPDATE "Products" SET "Sku" = 'NICE040', "UpdatedAt" = NOW() WHERE "Id" = 257; -- Cũ: 6-1001
UPDATE "Products" SET "Sku" = 'NICE041', "UpdatedAt" = NOW() WHERE "Id" = 258; -- Cũ: 6-1012
UPDATE "Products" SET "Sku" = 'NICE042', "UpdatedAt" = NOW() WHERE "Id" = 259; -- Cũ: 6-1013-đen vân
UPDATE "Products" SET "Sku" = 'NICE043', "UpdatedAt" = NOW() WHERE "Id" = 260; -- Cũ: 6-1502- Gỗ mát
UPDATE "Products" SET "Sku" = 'NICE044', "UpdatedAt" = NOW() WHERE "Id" = 261; -- Cũ: 6-1021
UPDATE "Products" SET "Sku" = 'NICE045', "UpdatedAt" = NOW() WHERE "Id" = 262; -- Cũ: 6-1016
UPDATE "Products" SET "Sku" = 'NICE046', "UpdatedAt" = NOW() WHERE "Id" = 263; -- Cũ: 6-6045
UPDATE "Products" SET "Sku" = 'NICE047', "UpdatedAt" = NOW() WHERE "Id" = 264; -- Cũ: 6-6040 A2
UPDATE "Products" SET "Sku" = 'NICE048', "UpdatedAt" = NOW() WHERE "Id" = 265; -- Cũ: 6-6036
UPDATE "Products" SET "Sku" = 'NICE049', "UpdatedAt" = NOW() WHERE "Id" = 266; -- Cũ: 6-6043
UPDATE "Products" SET "Sku" = 'NICE050', "UpdatedAt" = NOW() WHERE "Id" = 267; -- Cũ: 6-6031 A2
UPDATE "Products" SET "Sku" = 'NICE051', "UpdatedAt" = NOW() WHERE "Id" = 268; -- Cũ: 6-6030
UPDATE "Products" SET "Sku" = 'NICE052', "UpdatedAt" = NOW() WHERE "Id" = 269; -- Cũ: 6-6042
UPDATE "Products" SET "Sku" = 'NICE053', "UpdatedAt" = NOW() WHERE "Id" = 270; -- Cũ: 6-6041
UPDATE "Products" SET "Sku" = 'NICE054', "UpdatedAt" = NOW() WHERE "Id" = 271; -- Cũ: 6-6037
UPDATE "Products" SET "Sku" = 'NICE055', "UpdatedAt" = NOW() WHERE "Id" = 272; -- Cũ: 6-6043- A2
UPDATE "Products" SET "Sku" = 'NICE056', "UpdatedAt" = NOW() WHERE "Id" = 273; -- Cũ: 6-6031
UPDATE "Products" SET "Sku" = 'NICE057', "UpdatedAt" = NOW() WHERE "Id" = 274; -- Cũ: 6-6042- A2
UPDATE "Products" SET "Sku" = 'NICE058', "UpdatedAt" = NOW() WHERE "Id" = 275; -- Cũ: 6-6038
UPDATE "Products" SET "Sku" = 'NICE059', "UpdatedAt" = NOW() WHERE "Id" = 276; -- Cũ: 6-6030 A2
UPDATE "Products" SET "Sku" = 'NICE060', "UpdatedAt" = NOW() WHERE "Id" = 277; -- Cũ: 6-6040
UPDATE "Products" SET "Sku" = 'NICE061', "UpdatedAt" = NOW() WHERE "Id" = 278; -- Cũ: 8-6010
UPDATE "Products" SET "Sku" = 'NICE062', "UpdatedAt" = NOW() WHERE "Id" = 279; -- Cũ: 8-6021
UPDATE "Products" SET "Sku" = 'NICE063', "UpdatedAt" = NOW() WHERE "Id" = 280; -- Cũ: 8-6032 A2
UPDATE "Products" SET "Sku" = 'NICE064', "UpdatedAt" = NOW() WHERE "Id" = 281; -- Cũ: 8-6031
UPDATE "Products" SET "Sku" = 'NICE065', "UpdatedAt" = NOW() WHERE "Id" = 282; -- Cũ: 6-6400 A2
UPDATE "Products" SET "Sku" = 'NICE066', "UpdatedAt" = NOW() WHERE "Id" = 283; -- Cũ: 8-6029
UPDATE "Products" SET "Sku" = 'NICE067', "UpdatedAt" = NOW() WHERE "Id" = 284; -- Cũ: 6-6200
UPDATE "Products" SET "Sku" = 'NICE068', "UpdatedAt" = NOW() WHERE "Id" = 285; -- Cũ: 6-6100
UPDATE "Products" SET "Sku" = 'NICE069', "UpdatedAt" = NOW() WHERE "Id" = 286; -- Cũ: 8-6004
UPDATE "Products" SET "Sku" = 'NICE070', "UpdatedAt" = NOW() WHERE "Id" = 287; -- Cũ: 8-6003 A2
UPDATE "Products" SET "Sku" = 'NICE071', "UpdatedAt" = NOW() WHERE "Id" = 288; -- Cũ: 8-6019
UPDATE "Products" SET "Sku" = 'NICE072', "UpdatedAt" = NOW() WHERE "Id" = 289; -- Cũ: 8-6019 A2
UPDATE "Products" SET "Sku" = 'NICE073', "UpdatedAt" = NOW() WHERE "Id" = 290; -- Cũ: 8-6017
UPDATE "Products" SET "Sku" = 'NICE074', "UpdatedAt" = NOW() WHERE "Id" = 291; -- Cũ: 6-6400
UPDATE "Products" SET "Sku" = 'NICE075', "UpdatedAt" = NOW() WHERE "Id" = 292; -- Cũ: 6-6400 A3
UPDATE "Products" SET "Sku" = 'NICE076', "UpdatedAt" = NOW() WHERE "Id" = 293; -- Cũ: 8-6039 A2
UPDATE "Products" SET "Sku" = 'NICE077', "UpdatedAt" = NOW() WHERE "Id" = 294; -- Cũ: 8-601-vt
UPDATE "Products" SET "Sku" = 'NICE078', "UpdatedAt" = NOW() WHERE "Id" = 295; -- Cũ: 8-6041
UPDATE "Products" SET "Sku" = 'NICE079', "UpdatedAt" = NOW() WHERE "Id" = 296; -- Cũ: 8-6037
UPDATE "Products" SET "Sku" = 'NICE080', "UpdatedAt" = NOW() WHERE "Id" = 297; -- Cũ: 8-6036
UPDATE "Products" SET "Sku" = 'NICE081', "UpdatedAt" = NOW() WHERE "Id" = 298; -- Cũ: 8-6035
UPDATE "Products" SET "Sku" = 'NICE082', "UpdatedAt" = NOW() WHERE "Id" = 299; -- Cũ: 8-6045 a2
UPDATE "Products" SET "Sku" = 'NICE083', "UpdatedAt" = NOW() WHERE "Id" = 300; -- Cũ: 8-6045
UPDATE "Products" SET "Sku" = 'NICE084', "UpdatedAt" = NOW() WHERE "Id" = 301; -- Cũ: 8-6038
UPDATE "Products" SET "Sku" = 'NICE085', "UpdatedAt" = NOW() WHERE "Id" = 302; -- Cũ: 8-6039
UPDATE "Products" SET "Sku" = 'NICE086', "UpdatedAt" = NOW() WHERE "Id" = 303; -- Cũ: 8-6047 A2
UPDATE "Products" SET "Sku" = 'NICE087', "UpdatedAt" = NOW() WHERE "Id" = 304; -- Cũ: 8-6046 a2
UPDATE "Products" SET "Sku" = 'NICE088', "UpdatedAt" = NOW() WHERE "Id" = 305; -- Cũ: 8-6043
UPDATE "Products" SET "Sku" = 'NICE089', "UpdatedAt" = NOW() WHERE "Id" = 306; -- Cũ: 8-6042
UPDATE "Products" SET "Sku" = 'NICE090', "UpdatedAt" = NOW() WHERE "Id" = 307; -- Cũ: 8-6040
UPDATE "Products" SET "Sku" = 'NICE091', "UpdatedAt" = NOW() WHERE "Id" = 308; -- Cũ: 8-6200 A2
UPDATE "Products" SET "Sku" = 'NICE092', "UpdatedAt" = NOW() WHERE "Id" = 309; -- Cũ: MN612.616 A1-bóng-55(24.11.24)
UPDATE "Products" SET "Sku" = 'NICE093', "UpdatedAt" = NOW() WHERE "Id" = 310; -- Cũ: MN612.614-KHÓI
UPDATE "Products" SET "Sku" = 'NICE094', "UpdatedAt" = NOW() WHERE "Id" = 311; -- Cũ: MN612.510 A1-mát-57(3.1.26)
UPDATE "Products" SET "Sku" = 'NICE095', "UpdatedAt" = NOW() WHERE "Id" = 312; -- Cũ: 8-6200
UPDATE "Products" SET "Sku" = 'NICE096', "UpdatedAt" = NOW() WHERE "Id" = 313; -- Cũ: 11-646-VT-(đ53:16.3.26)
UPDATE "Products" SET "Sku" = 'NICE097', "UpdatedAt" = NOW() WHERE "Id" = 314; -- Cũ: 11-601-đ55(40h/k)-12.3.26 A2-40H/K
UPDATE "Products" SET "Sku" = 'NICE098', "UpdatedAt" = NOW() WHERE "Id" = 315; -- Cũ: 11-602
UPDATE "Products" SET "Sku" = 'NICE099', "UpdatedAt" = NOW() WHERE "Id" = 316; -- Cũ: 8-602
UPDATE "Products" SET "Sku" = 'NICE100', "UpdatedAt" = NOW() WHERE "Id" = 317; -- Cũ: 11-602-D53(28.3.26) A2-43H/K
UPDATE "Products" SET "Sku" = 'NICE101', "UpdatedAt" = NOW() WHERE "Id" = 318; -- Cũ: MN612.618 A1-bóng-Đ58(3.3.26)
UPDATE "Products" SET "Sku" = 'NICE102', "UpdatedAt" = NOW() WHERE "Id" = 319; -- Cũ: 11-646-VT-(đ55:16.3.26) A2(40h/k)
UPDATE "Products" SET "Sku" = 'NICE103', "UpdatedAt" = NOW() WHERE "Id" = 320; -- Cũ: 11-645
UPDATE "Products" SET "Sku" = 'NICE104', "UpdatedAt" = NOW() WHERE "Id" = 321; -- Cũ: 11-645 A2-40H/K
UPDATE "Products" SET "Sku" = 'NICE105', "UpdatedAt" = NOW() WHERE "Id" = 322; -- Cũ: 11-601-đ52(43h/k)-7.4.26
UPDATE "Products" SET "Sku" = 'NICE106', "UpdatedAt" = NOW() WHERE "Id" = 323; -- Cũ: 46512-02DẦY 12mm
UPDATE "Products" SET "Sku" = 'NICE107', "UpdatedAt" = NOW() WHERE "Id" = 324; -- Cũ: 46512-03DẦY 12mm
UPDATE "Products" SET "Sku" = 'NICE108', "UpdatedAt" = NOW() WHERE "Id" = 325; -- Cũ: 46512-01-DẦY 12mm

-- >>> Nhà cung cấp: Takao (Prefix: TAKAO)
UPDATE "Products" SET "Sku" = 'TAKAO001', "UpdatedAt" = NOW() WHERE "Id" = 326; -- Cũ: 13102
UPDATE "Products" SET "Sku" = 'TAKAO002', "UpdatedAt" = NOW() WHERE "Id" = 327; -- Cũ: 13202-ĐIỂM
UPDATE "Products" SET "Sku" = 'TAKAO003', "UpdatedAt" = NOW() WHERE "Id" = 328; -- Cũ: 97-606
UPDATE "Products" SET "Sku" = 'TAKAO004', "UpdatedAt" = NOW() WHERE "Id" = 329; -- Cũ: 97-106
UPDATE "Products" SET "Sku" = 'TAKAO005', "UpdatedAt" = NOW() WHERE "Id" = 330; -- Cũ: 97-105
UPDATE "Products" SET "Sku" = 'TAKAO006', "UpdatedAt" = NOW() WHERE "Id" = 331; -- Cũ: 97-665
UPDATE "Products" SET "Sku" = 'TAKAO007', "UpdatedAt" = NOW() WHERE "Id" = 332; -- Cũ: 97-104
UPDATE "Products" SET "Sku" = 'TAKAO008', "UpdatedAt" = NOW() WHERE "Id" = 333; -- Cũ: 97-604
UPDATE "Products" SET "Sku" = 'TAKAO009', "UpdatedAt" = NOW() WHERE "Id" = 334; -- Cũ: 97-101
UPDATE "Products" SET "Sku" = 'TAKAO010', "UpdatedAt" = NOW() WHERE "Id" = 335; -- Cũ: 97-855
UPDATE "Products" SET "Sku" = 'TAKAO011', "UpdatedAt" = NOW() WHERE "Id" = 336; -- Cũ: 97-654
UPDATE "Products" SET "Sku" = 'TAKAO012', "UpdatedAt" = NOW() WHERE "Id" = 337; -- Cũ: 97-601
UPDATE "Products" SET "Sku" = 'TAKAO013', "UpdatedAt" = NOW() WHERE "Id" = 338; -- Cũ: 97-854
UPDATE "Products" SET "Sku" = 'TAKAO014', "UpdatedAt" = NOW() WHERE "Id" = 339; -- Cũ: 13103
UPDATE "Products" SET "Sku" = 'TAKAO015', "UpdatedAt" = NOW() WHERE "Id" = 340; -- Cũ: 97-653
UPDATE "Products" SET "Sku" = 'TAKAO016', "UpdatedAt" = NOW() WHERE "Id" = 341; -- Cũ: 43600-điểm
UPDATE "Products" SET "Sku" = 'TAKAO017', "UpdatedAt" = NOW() WHERE "Id" = 342; -- Cũ: 73501-khói
UPDATE "Products" SET "Sku" = 'TAKAO018', "UpdatedAt" = NOW() WHERE "Id" = 343; -- Cũ: 14113-khói
UPDATE "Products" SET "Sku" = 'TAKAO019', "UpdatedAt" = NOW() WHERE "Id" = 344; -- Cũ: 73602-điểm
UPDATE "Products" SET "Sku" = 'TAKAO020', "UpdatedAt" = NOW() WHERE "Id" = 345; -- Cũ: 13106
UPDATE "Products" SET "Sku" = 'TAKAO021', "UpdatedAt" = NOW() WHERE "Id" = 346; -- Cũ: 73601-điểm
UPDATE "Products" SET "Sku" = 'TAKAO022', "UpdatedAt" = NOW() WHERE "Id" = 347; -- Cũ: 73503-đậm
UPDATE "Products" SET "Sku" = 'TAKAO023', "UpdatedAt" = NOW() WHERE "Id" = 348; -- Cũ: 13206 ĐIỂM
UPDATE "Products" SET "Sku" = 'TAKAO024', "UpdatedAt" = NOW() WHERE "Id" = 349; -- Cũ: 73507-đậm
UPDATE "Products" SET "Sku" = 'TAKAO025', "UpdatedAt" = NOW() WHERE "Id" = 350; -- Cũ: 14101(1H=1.28)
UPDATE "Products" SET "Sku" = 'TAKAO026', "UpdatedAt" = NOW() WHERE "Id" = 351; -- Cũ: 43500-Trắng tinh bs
UPDATE "Products" SET "Sku" = 'TAKAO027', "UpdatedAt" = NOW() WHERE "Id" = 352; -- Cũ: 73506-nhạt
UPDATE "Products" SET "Sku" = 'TAKAO028', "UpdatedAt" = NOW() WHERE "Id" = 353; -- Cũ: 73502-nhạt
UPDATE "Products" SET "Sku" = 'TAKAO029', "UpdatedAt" = NOW() WHERE "Id" = 354; -- Cũ: 14213-điểm
UPDATE "Products" SET "Sku" = 'TAKAO030', "UpdatedAt" = NOW() WHERE "Id" = 355; -- Cũ: 73606-điểm
UPDATE "Products" SET "Sku" = 'TAKAO031', "UpdatedAt" = NOW() WHERE "Id" = 356; -- Cũ: 16912
UPDATE "Products" SET "Sku" = 'TAKAO032', "UpdatedAt" = NOW() WHERE "Id" = 357; -- Cũ: 16106 -K1
UPDATE "Products" SET "Sku" = 'TAKAO033', "UpdatedAt" = NOW() WHERE "Id" = 358; -- Cũ: 16917
UPDATE "Products" SET "Sku" = 'TAKAO034', "UpdatedAt" = NOW() WHERE "Id" = 359; -- Cũ: 16901
UPDATE "Products" SET "Sku" = 'TAKAO035', "UpdatedAt" = NOW() WHERE "Id" = 360; -- Cũ: 14209-điểm
UPDATE "Products" SET "Sku" = 'TAKAO036', "UpdatedAt" = NOW() WHERE "Id" = 361; -- Cũ: 16906
UPDATE "Products" SET "Sku" = 'TAKAO037', "UpdatedAt" = NOW() WHERE "Id" = 362; -- Cũ: 16916
UPDATE "Products" SET "Sku" = 'TAKAO038', "UpdatedAt" = NOW() WHERE "Id" = 363; -- Cũ: 14110
UPDATE "Products" SET "Sku" = 'TAKAO039', "UpdatedAt" = NOW() WHERE "Id" = 364; -- Cũ: 74202-điểm
UPDATE "Products" SET "Sku" = 'TAKAO040', "UpdatedAt" = NOW() WHERE "Id" = 365; -- Cũ: 16913
UPDATE "Products" SET "Sku" = 'TAKAO041', "UpdatedAt" = NOW() WHERE "Id" = 366; -- Cũ: 74103
UPDATE "Products" SET "Sku" = 'TAKAO042', "UpdatedAt" = NOW() WHERE "Id" = 367; -- Cũ: 16911
UPDATE "Products" SET "Sku" = 'TAKAO043', "UpdatedAt" = NOW() WHERE "Id" = 368; -- Cũ: 14109
UPDATE "Products" SET "Sku" = 'TAKAO044', "UpdatedAt" = NOW() WHERE "Id" = 369; -- Cũ: 74102
UPDATE "Products" SET "Sku" = 'TAKAO045', "UpdatedAt" = NOW() WHERE "Id" = 370; -- Cũ: 16902
UPDATE "Products" SET "Sku" = 'TAKAO046', "UpdatedAt" = NOW() WHERE "Id" = 371; -- Cũ: 17006
UPDATE "Products" SET "Sku" = 'TAKAO047', "UpdatedAt" = NOW() WHERE "Id" = 372; -- Cũ: 17154
UPDATE "Products" SET "Sku" = 'TAKAO048', "UpdatedAt" = NOW() WHERE "Id" = 373; -- Cũ: 14603(1.44M2)
UPDATE "Products" SET "Sku" = 'TAKAO049', "UpdatedAt" = NOW() WHERE "Id" = 374; -- Cũ: 16.126
UPDATE "Products" SET "Sku" = 'TAKAO050', "UpdatedAt" = NOW() WHERE "Id" = 375; -- Cũ: 76105
UPDATE "Products" SET "Sku" = 'TAKAO051', "UpdatedAt" = NOW() WHERE "Id" = 376; -- Cũ: 17153
UPDATE "Products" SET "Sku" = 'TAKAO052', "UpdatedAt" = NOW() WHERE "Id" = 377; -- Cũ: 17156
UPDATE "Products" SET "Sku" = 'TAKAO053', "UpdatedAt" = NOW() WHERE "Id" = 378; -- Cũ: 18901
UPDATE "Products" SET "Sku" = 'TAKAO054', "UpdatedAt" = NOW() WHERE "Id" = 379; -- Cũ: 17001
UPDATE "Products" SET "Sku" = 'TAKAO055', "UpdatedAt" = NOW() WHERE "Id" = 380; -- Cũ: 76103
UPDATE "Products" SET "Sku" = 'TAKAO056', "UpdatedAt" = NOW() WHERE "Id" = 381; -- Cũ: 76102
UPDATE "Products" SET "Sku" = 'TAKAO057', "UpdatedAt" = NOW() WHERE "Id" = 382; -- Cũ: 17155
UPDATE "Products" SET "Sku" = 'TAKAO058', "UpdatedAt" = NOW() WHERE "Id" = 383; -- Cũ: 14602
UPDATE "Products" SET "Sku" = 'TAKAO059', "UpdatedAt" = NOW() WHERE "Id" = 384; -- Cũ: 17152
UPDATE "Products" SET "Sku" = 'TAKAO060', "UpdatedAt" = NOW() WHERE "Id" = 385; -- Cũ: 17151
UPDATE "Products" SET "Sku" = 'TAKAO061', "UpdatedAt" = NOW() WHERE "Id" = 386; -- Cũ: 18126
UPDATE "Products" SET "Sku" = 'TAKAO062', "UpdatedAt" = NOW() WHERE "Id" = 387; -- Cũ: 48302
UPDATE "Products" SET "Sku" = 'TAKAO063', "UpdatedAt" = NOW() WHERE "Id" = 388; -- Cũ: 18402
UPDATE "Products" SET "Sku" = 'TAKAO064', "UpdatedAt" = NOW() WHERE "Id" = 389; -- Cũ: 18902
UPDATE "Products" SET "Sku" = 'TAKAO065', "UpdatedAt" = NOW() WHERE "Id" = 390; -- Cũ: 18916
UPDATE "Products" SET "Sku" = 'TAKAO066', "UpdatedAt" = NOW() WHERE "Id" = 391; -- Cũ: 48304
UPDATE "Products" SET "Sku" = 'TAKAO067', "UpdatedAt" = NOW() WHERE "Id" = 392; -- Cũ: 78001
UPDATE "Products" SET "Sku" = 'TAKAO068', "UpdatedAt" = NOW() WHERE "Id" = 393; -- Cũ: 18913
UPDATE "Products" SET "Sku" = 'TAKAO069', "UpdatedAt" = NOW() WHERE "Id" = 394; -- Cũ: 78002
UPDATE "Products" SET "Sku" = 'TAKAO070', "UpdatedAt" = NOW() WHERE "Id" = 395; -- Cũ: 18911
UPDATE "Products" SET "Sku" = 'TAKAO071', "UpdatedAt" = NOW() WHERE "Id" = 396; -- Cũ: 18917
UPDATE "Products" SET "Sku" = 'TAKAO072', "UpdatedAt" = NOW() WHERE "Id" = 397; -- Cũ: 18912
UPDATE "Products" SET "Sku" = 'TAKAO073', "UpdatedAt" = NOW() WHERE "Id" = 398; -- Cũ: 18906
UPDATE "Products" SET "Sku" = 'TAKAO074', "UpdatedAt" = NOW() WHERE "Id" = 399; -- Cũ: 78008
UPDATE "Products" SET "Sku" = 'TAKAO075', "UpdatedAt" = NOW() WHERE "Id" = 400; -- Cũ: 78003
UPDATE "Products" SET "Sku" = 'TAKAO076', "UpdatedAt" = NOW() WHERE "Id" = 401; -- Cũ: 18701
UPDATE "Products" SET "Sku" = 'TAKAO077', "UpdatedAt" = NOW() WHERE "Id" = 402; -- Cũ: 71.101
UPDATE "Products" SET "Sku" = 'TAKAO078', "UpdatedAt" = NOW() WHERE "Id" = 403; -- Cũ: 18706
UPDATE "Products" SET "Sku" = 'TAKAO079', "UpdatedAt" = NOW() WHERE "Id" = 404; -- Cũ: 18704
UPDATE "Products" SET "Sku" = 'TAKAO080', "UpdatedAt" = NOW() WHERE "Id" = 405; -- Cũ: 71103
UPDATE "Products" SET "Sku" = 'TAKAO081', "UpdatedAt" = NOW() WHERE "Id" = 406; -- Cũ: 11106
UPDATE "Products" SET "Sku" = 'TAKAO082', "UpdatedAt" = NOW() WHERE "Id" = 407; -- Cũ: 78703
UPDATE "Products" SET "Sku" = 'TAKAO083', "UpdatedAt" = NOW() WHERE "Id" = 408; -- Cũ: 18707
UPDATE "Products" SET "Sku" = 'TAKAO084', "UpdatedAt" = NOW() WHERE "Id" = 409; -- Cũ: 11102
UPDATE "Products" SET "Sku" = 'TAKAO085', "UpdatedAt" = NOW() WHERE "Id" = 410; -- Cũ: 78705
UPDATE "Products" SET "Sku" = 'TAKAO086', "UpdatedAt" = NOW() WHERE "Id" = 411; -- Cũ: 71102
UPDATE "Products" SET "Sku" = 'TAKAO087', "UpdatedAt" = NOW() WHERE "Id" = 412; -- Cũ: 11103
UPDATE "Products" SET "Sku" = 'TAKAO088', "UpdatedAt" = NOW() WHERE "Id" = 413; -- Cũ: 11104
UPDATE "Products" SET "Sku" = 'TAKAO089', "UpdatedAt" = NOW() WHERE "Id" = 414; -- Cũ: 11101
UPDATE "Products" SET "Sku" = 'TAKAO090', "UpdatedAt" = NOW() WHERE "Id" = 415; -- Cũ: 78702
UPDATE "Products" SET "Sku" = 'TAKAO091', "UpdatedAt" = NOW() WHERE "Id" = 416; -- Cũ: 71105
UPDATE "Products" SET "Sku" = 'TAKAO092', "UpdatedAt" = NOW() WHERE "Id" = 417; -- Cũ: 71108

-- >>> Nhà cung cấp: Vĩnh Thắng (Prefix: VT)
UPDATE "Products" SET "Sku" = 'VT001', "UpdatedAt" = NOW() WHERE "Id" = 418; -- Cũ: FR5001
UPDATE "Products" SET "Sku" = 'VT002', "UpdatedAt" = NOW() WHERE "Id" = 419; -- Cũ: FB3603-ĐẬM
UPDATE "Products" SET "Sku" = 'VT003', "UpdatedAt" = NOW() WHERE "Id" = 420; -- Cũ: FB3603-ĐIỂM
UPDATE "Products" SET "Sku" = 'VT004', "UpdatedAt" = NOW() WHERE "Id" = 421; -- Cũ: FB3601-KHÓI
UPDATE "Products" SET "Sku" = 'VT005', "UpdatedAt" = NOW() WHERE "Id" = 422; -- Cũ: FB3605-NHẠT
UPDATE "Products" SET "Sku" = 'VT006', "UpdatedAt" = NOW() WHERE "Id" = 423; -- Cũ: FB3603-NHẠT
UPDATE "Products" SET "Sku" = 'VT007', "UpdatedAt" = NOW() WHERE "Id" = 424; -- Cũ: FR5004
UPDATE "Products" SET "Sku" = 'VT008', "UpdatedAt" = NOW() WHERE "Id" = 425; -- Cũ: FB3604-NHẠT
UPDATE "Products" SET "Sku" = 'VT009', "UpdatedAt" = NOW() WHERE "Id" = 426; -- Cũ: FR5509
UPDATE "Products" SET "Sku" = 'VT010', "UpdatedAt" = NOW() WHERE "Id" = 427; -- Cũ: FR5008
UPDATE "Products" SET "Sku" = 'VT011', "UpdatedAt" = NOW() WHERE "Id" = 428; -- Cũ: FB3604-ĐIỂM
UPDATE "Products" SET "Sku" = 'VT012', "UpdatedAt" = NOW() WHERE "Id" = 429; -- Cũ: FR5002
UPDATE "Products" SET "Sku" = 'VT013', "UpdatedAt" = NOW() WHERE "Id" = 430; -- Cũ: FR5007
UPDATE "Products" SET "Sku" = 'VT014', "UpdatedAt" = NOW() WHERE "Id" = 431; -- Cũ: FR5005
UPDATE "Products" SET "Sku" = 'VT015', "UpdatedAt" = NOW() WHERE "Id" = 432; -- Cũ: FB3604-ĐẬM
UPDATE "Products" SET "Sku" = 'VT016', "UpdatedAt" = NOW() WHERE "Id" = 433; -- Cũ: FB3607-ĐẬM
UPDATE "Products" SET "Sku" = 'VT017', "UpdatedAt" = NOW() WHERE "Id" = 434; -- Cũ: FB3607-ĐIỂM
UPDATE "Products" SET "Sku" = 'VT018', "UpdatedAt" = NOW() WHERE "Id" = 435; -- Cũ: FB3605-ĐẬM
UPDATE "Products" SET "Sku" = 'VT019', "UpdatedAt" = NOW() WHERE "Id" = 436; -- Cũ: FM5801
UPDATE "Products" SET "Sku" = 'VT020', "UpdatedAt" = NOW() WHERE "Id" = 437; -- Cũ: FM5803
UPDATE "Products" SET "Sku" = 'VT021', "UpdatedAt" = NOW() WHERE "Id" = 438; -- Cũ: FM4601
UPDATE "Products" SET "Sku" = 'VT022', "UpdatedAt" = NOW() WHERE "Id" = 439; -- Cũ: FB3610-ĐIỂM
UPDATE "Products" SET "Sku" = 'VT023', "UpdatedAt" = NOW() WHERE "Id" = 440; -- Cũ: FM4605
UPDATE "Products" SET "Sku" = 'VT024', "UpdatedAt" = NOW() WHERE "Id" = 441; -- Cũ: FB3607-NHẠT
UPDATE "Products" SET "Sku" = 'VT025', "UpdatedAt" = NOW() WHERE "Id" = 442; -- Cũ: FM4604
UPDATE "Products" SET "Sku" = 'VT026', "UpdatedAt" = NOW() WHERE "Id" = 443; -- Cũ: FM4603
UPDATE "Products" SET "Sku" = 'VT027', "UpdatedAt" = NOW() WHERE "Id" = 444; -- Cũ: FM5802
UPDATE "Products" SET "Sku" = 'VT028', "UpdatedAt" = NOW() WHERE "Id" = 445; -- Cũ: FB3610-ĐẬM
UPDATE "Products" SET "Sku" = 'VT029', "UpdatedAt" = NOW() WHERE "Id" = 446; -- Cũ: FB3610-NHẠT
UPDATE "Products" SET "Sku" = 'VT030', "UpdatedAt" = NOW() WHERE "Id" = 447; -- Cũ: FB3605-ĐIỂM
UPDATE "Products" SET "Sku" = 'VT031', "UpdatedAt" = NOW() WHERE "Id" = 448; -- Cũ: FP46065
UPDATE "Products" SET "Sku" = 'VT032', "UpdatedAt" = NOW() WHERE "Id" = 449; -- Cũ: F6602
UPDATE "Products" SET "Sku" = 'VT033', "UpdatedAt" = NOW() WHERE "Id" = 450; -- Cũ: FP46062
UPDATE "Products" SET "Sku" = 'VT034', "UpdatedAt" = NOW() WHERE "Id" = 451; -- Cũ: F3305
UPDATE "Products" SET "Sku" = 'VT035', "UpdatedAt" = NOW() WHERE "Id" = 452; -- Cũ: FM3308
UPDATE "Products" SET "Sku" = 'VT036', "UpdatedAt" = NOW() WHERE "Id" = 453; -- Cũ: FM3310
UPDATE "Products" SET "Sku" = 'VT037', "UpdatedAt" = NOW() WHERE "Id" = 454; -- Cũ: F6604
UPDATE "Products" SET "Sku" = 'VT038', "UpdatedAt" = NOW() WHERE "Id" = 455; -- Cũ: F6616
UPDATE "Products" SET "Sku" = 'VT039', "UpdatedAt" = NOW() WHERE "Id" = 456; -- Cũ: FP46061

-- >>> Nhà cung cấp: Dmax + Mira (Prefix: DMAX)
UPDATE "Products" SET "Sku" = 'DMAX001', "UpdatedAt" = NOW() WHERE "Id" = 457; -- Cũ: DA8802
UPDATE "Products" SET "Sku" = 'DMAX002', "UpdatedAt" = NOW() WHERE "Id" = 458; -- Cũ: DA6604
UPDATE "Products" SET "Sku" = 'DMAX003', "UpdatedAt" = NOW() WHERE "Id" = 459; -- Cũ: DA6601
UPDATE "Products" SET "Sku" = 'DMAX004', "UpdatedAt" = NOW() WHERE "Id" = 460; -- Cũ: DA8804
UPDATE "Products" SET "Sku" = 'DMAX005', "UpdatedAt" = NOW() WHERE "Id" = 461; -- Cũ: DA1001
UPDATE "Products" SET "Sku" = 'DMAX006', "UpdatedAt" = NOW() WHERE "Id" = 462; -- Cũ: DA1004
UPDATE "Products" SET "Sku" = 'DMAX007', "UpdatedAt" = NOW() WHERE "Id" = 463; -- Cũ: DA6603
UPDATE "Products" SET "Sku" = 'DMAX008', "UpdatedAt" = NOW() WHERE "Id" = 464; -- Cũ: DA8801
UPDATE "Products" SET "Sku" = 'DMAX009', "UpdatedAt" = NOW() WHERE "Id" = 465; -- Cũ: DA8806
UPDATE "Products" SET "Sku" = 'DMAX010', "UpdatedAt" = NOW() WHERE "Id" = 466; -- Cũ: DA61205
UPDATE "Products" SET "Sku" = 'DMAX011', "UpdatedAt" = NOW() WHERE "Id" = 467; -- Cũ: DA6602
UPDATE "Products" SET "Sku" = 'DMAX012', "UpdatedAt" = NOW() WHERE "Id" = 468; -- Cũ: DA6606
UPDATE "Products" SET "Sku" = 'DMAX013', "UpdatedAt" = NOW() WHERE "Id" = 469; -- Cũ: DA1002
UPDATE "Products" SET "Sku" = 'DMAX014', "UpdatedAt" = NOW() WHERE "Id" = 470; -- Cũ: DA8803
UPDATE "Products" SET "Sku" = 'DMAX015', "UpdatedAt" = NOW() WHERE "Id" = 471; -- Cũ: MR12902
UPDATE "Products" SET "Sku" = 'DMAX016', "UpdatedAt" = NOW() WHERE "Id" = 472; -- Cũ: MR11034
UPDATE "Products" SET "Sku" = 'DMAX017', "UpdatedAt" = NOW() WHERE "Id" = 473; -- Cũ: MR11039
UPDATE "Products" SET "Sku" = 'DMAX018', "UpdatedAt" = NOW() WHERE "Id" = 474; -- Cũ: MR11037

-- >>> Nhà cung cấp: Royal + Ấn Độ (Prefix: RA)
UPDATE "Products" SET "Sku" = 'RA001', "UpdatedAt" = NOW() WHERE "Id" = 475; -- Cũ: DP515
UPDATE "Products" SET "Sku" = 'RA002', "UpdatedAt" = NOW() WHERE "Id" = 476; -- Cũ: BS3605-DH
UPDATE "Products" SET "Sku" = 'RA003', "UpdatedAt" = NOW() WHERE "Id" = 477; -- Cũ: DP518
UPDATE "Products" SET "Sku" = 'RA004', "UpdatedAt" = NOW() WHERE "Id" = 478; -- Cũ: CAFÉ
UPDATE "Products" SET "Sku" = 'RA005', "UpdatedAt" = NOW() WHERE "Id" = 479; -- Cũ: DP514
UPDATE "Products" SET "Sku" = 'RA006', "UpdatedAt" = NOW() WHERE "Id" = 480; -- Cũ: BS3601-P
UPDATE "Products" SET "Sku" = 'RA007', "UpdatedAt" = NOW() WHERE "Id" = 481; -- Cũ: 1683
UPDATE "Products" SET "Sku" = 'RA008', "UpdatedAt" = NOW() WHERE "Id" = 482; -- Cũ: 1543
UPDATE "Products" SET "Sku" = 'RA009', "UpdatedAt" = NOW() WHERE "Id" = 483; -- Cũ: LIMBER
UPDATE "Products" SET "Sku" = 'RA010', "UpdatedAt" = NOW() WHERE "Id" = 484; -- Cũ: APRICOT
UPDATE "Products" SET "Sku" = 'RA011', "UpdatedAt" = NOW() WHERE "Id" = 485; -- Cũ: 1347
UPDATE "Products" SET "Sku" = 'RA012', "UpdatedAt" = NOW() WHERE "Id" = 486; -- Cũ: LIFE
UPDATE "Products" SET "Sku" = 'RA013', "UpdatedAt" = NOW() WHERE "Id" = 487; -- Cũ: 1072
UPDATE "Products" SET "Sku" = 'RA014', "UpdatedAt" = NOW() WHERE "Id" = 488; -- Cũ: Keo CK vỏ cam(bao 25kg)
UPDATE "Products" SET "Sku" = 'RA015', "UpdatedAt" = NOW() WHERE "Id" = 489; -- Cũ: TP602
UPDATE "Products" SET "Sku" = 'RA016', "UpdatedAt" = NOW() WHERE "Id" = 490; -- Cũ: keo 20 kg
UPDATE "Products" SET "Sku" = 'RA017', "UpdatedAt" = NOW() WHERE "Id" = 491; -- Cũ: NÊM ĐỎ
UPDATE "Products" SET "Sku" = 'RA018', "UpdatedAt" = NOW() WHERE "Id" = 492; -- Cũ: KE 1MM
UPDATE "Products" SET "Sku" = 'RA019', "UpdatedAt" = NOW() WHERE "Id" = 493; -- Cũ: KE 1,5 MM

-- >>> Nhà cung cấp: Toko (Prefix: TOKO)
UPDATE "Products" SET "Sku" = 'TOKO001', "UpdatedAt" = NOW() WHERE "Id" = 494; -- Cũ: 632.009
UPDATE "Products" SET "Sku" = 'TOKO002', "UpdatedAt" = NOW() WHERE "Id" = 495; -- Cũ: 632.005
UPDATE "Products" SET "Sku" = 'TOKO003', "UpdatedAt" = NOW() WHERE "Id" = 496; -- Cũ: 3002
UPDATE "Products" SET "Sku" = 'TOKO004', "UpdatedAt" = NOW() WHERE "Id" = 497; -- Cũ: 3004
UPDATE "Products" SET "Sku" = 'TOKO005', "UpdatedAt" = NOW() WHERE "Id" = 498; -- Cũ: 46304-(6v/h)
UPDATE "Products" SET "Sku" = 'TOKO006', "UpdatedAt" = NOW() WHERE "Id" = 499; -- Cũ: 5302
UPDATE "Products" SET "Sku" = 'TOKO007', "UpdatedAt" = NOW() WHERE "Id" = 500; -- Cũ: 632.602
UPDATE "Products" SET "Sku" = 'TOKO008', "UpdatedAt" = NOW() WHERE "Id" = 501; -- Cũ: 3005
UPDATE "Products" SET "Sku" = 'TOKO009', "UpdatedAt" = NOW() WHERE "Id" = 502; -- Cũ: 46302-(8v/h)
UPDATE "Products" SET "Sku" = 'TOKO010', "UpdatedAt" = NOW() WHERE "Id" = 503; -- Cũ: 46304- (8v/h)
UPDATE "Products" SET "Sku" = 'TOKO011', "UpdatedAt" = NOW() WHERE "Id" = 504; -- Cũ: 5306
UPDATE "Products" SET "Sku" = 'TOKO012', "UpdatedAt" = NOW() WHERE "Id" = 505; -- Cũ: 5301
UPDATE "Products" SET "Sku" = 'TOKO013', "UpdatedAt" = NOW() WHERE "Id" = 506; -- Cũ: 46301-(8v/h)
UPDATE "Products" SET "Sku" = 'TOKO014', "UpdatedAt" = NOW() WHERE "Id" = 507; -- Cũ: 3003
UPDATE "Products" SET "Sku" = 'TOKO015', "UpdatedAt" = NOW() WHERE "Id" = 508; -- Cũ: 5305
UPDATE "Products" SET "Sku" = 'TOKO016', "UpdatedAt" = NOW() WHERE "Id" = 509; -- Cũ: 4832009
UPDATE "Products" SET "Sku" = 'TOKO017', "UpdatedAt" = NOW() WHERE "Id" = 510; -- Cũ: 4832011
UPDATE "Products" SET "Sku" = 'TOKO018', "UpdatedAt" = NOW() WHERE "Id" = 511; -- Cũ: 632.605
UPDATE "Products" SET "Sku" = 'TOKO019', "UpdatedAt" = NOW() WHERE "Id" = 512; -- Cũ: 4832010 Đ
UPDATE "Products" SET "Sku" = 'TOKO020', "UpdatedAt" = NOW() WHERE "Id" = 513; -- Cũ: 632.603
UPDATE "Products" SET "Sku" = 'TOKO021', "UpdatedAt" = NOW() WHERE "Id" = 514; -- Cũ: 4832007 Đ
UPDATE "Products" SET "Sku" = 'TOKO022', "UpdatedAt" = NOW() WHERE "Id" = 515; -- Cũ: 4832002 Đ
UPDATE "Products" SET "Sku" = 'TOKO023', "UpdatedAt" = NOW() WHERE "Id" = 516; -- Cũ: 4832004 Đ
UPDATE "Products" SET "Sku" = 'TOKO024', "UpdatedAt" = NOW() WHERE "Id" = 517; -- Cũ: 4832003
UPDATE "Products" SET "Sku" = 'TOKO025', "UpdatedAt" = NOW() WHERE "Id" = 518; -- Cũ: 4832005-A2
UPDATE "Products" SET "Sku" = 'TOKO026', "UpdatedAt" = NOW() WHERE "Id" = 519; -- Cũ: 4832001
UPDATE "Products" SET "Sku" = 'TOKO027', "UpdatedAt" = NOW() WHERE "Id" = 520; -- Cũ: 632.608
UPDATE "Products" SET "Sku" = 'TOKO028', "UpdatedAt" = NOW() WHERE "Id" = 521; -- Cũ: 632.604
UPDATE "Products" SET "Sku" = 'TOKO029', "UpdatedAt" = NOW() WHERE "Id" = 522; -- Cũ: 4832006
UPDATE "Products" SET "Sku" = 'TOKO030', "UpdatedAt" = NOW() WHERE "Id" = 523; -- Cũ: 4832005
UPDATE "Products" SET "Sku" = 'TOKO031', "UpdatedAt" = NOW() WHERE "Id" = 524; -- Cũ: 336004-Đ
UPDATE "Products" SET "Sku" = 'TOKO032', "UpdatedAt" = NOW() WHERE "Id" = 525; -- Cũ: 336007-Đ
UPDATE "Products" SET "Sku" = 'TOKO033', "UpdatedAt" = NOW() WHERE "Id" = 526; -- Cũ: 336011- A2
UPDATE "Products" SET "Sku" = 'TOKO034', "UpdatedAt" = NOW() WHERE "Id" = 527; -- Cũ: 336008
UPDATE "Products" SET "Sku" = 'TOKO035', "UpdatedAt" = NOW() WHERE "Id" = 528; -- Cũ: 832.001
UPDATE "Products" SET "Sku" = 'TOKO036', "UpdatedAt" = NOW() WHERE "Id" = 529; -- Cũ: 832.003
UPDATE "Products" SET "Sku" = 'TOKO037', "UpdatedAt" = NOW() WHERE "Id" = 530; -- Cũ: 336001
UPDATE "Products" SET "Sku" = 'TOKO038', "UpdatedAt" = NOW() WHERE "Id" = 531; -- Cũ: 832.002
UPDATE "Products" SET "Sku" = 'TOKO039', "UpdatedAt" = NOW() WHERE "Id" = 532; -- Cũ: 832.005
UPDATE "Products" SET "Sku" = 'TOKO040', "UpdatedAt" = NOW() WHERE "Id" = 533; -- Cũ: 832.008
UPDATE "Products" SET "Sku" = 'TOKO041', "UpdatedAt" = NOW() WHERE "Id" = 534; -- Cũ: 832.014
UPDATE "Products" SET "Sku" = 'TOKO042', "UpdatedAt" = NOW() WHERE "Id" = 535; -- Cũ: 336003
UPDATE "Products" SET "Sku" = 'TOKO043', "UpdatedAt" = NOW() WHERE "Id" = 536; -- Cũ: 336006
UPDATE "Products" SET "Sku" = 'TOKO044', "UpdatedAt" = NOW() WHERE "Id" = 537; -- Cũ: 336002-Đ
UPDATE "Products" SET "Sku" = 'TOKO045', "UpdatedAt" = NOW() WHERE "Id" = 538; -- Cũ: 832.004

-- >>> Nhà cung cấp: Á Mỹ (Prefix: AMY)
UPDATE "Products" SET "Sku" = 'AMY001', "UpdatedAt" = NOW() WHERE "Id" = 539; -- Cũ: AM 3062
UPDATE "Products" SET "Sku" = 'AMY002', "UpdatedAt" = NOW() WHERE "Id" = 540; -- Cũ: AM5060
UPDATE "Products" SET "Sku" = 'AMY003', "UpdatedAt" = NOW() WHERE "Id" = 541; -- Cũ: AM 3061
UPDATE "Products" SET "Sku" = 'AMY004', "UpdatedAt" = NOW() WHERE "Id" = 542; -- Cũ: AM5072
UPDATE "Products" SET "Sku" = 'AMY005', "UpdatedAt" = NOW() WHERE "Id" = 543; -- Cũ: AM8049
UPDATE "Products" SET "Sku" = 'AMY006', "UpdatedAt" = NOW() WHERE "Id" = 544; -- Cũ: AM 6824
UPDATE "Products" SET "Sku" = 'AMY007', "UpdatedAt" = NOW() WHERE "Id" = 545; -- Cũ: AM 5069
UPDATE "Products" SET "Sku" = 'AMY008', "UpdatedAt" = NOW() WHERE "Id" = 546; -- Cũ: AM 6825
UPDATE "Products" SET "Sku" = 'AMY009', "UpdatedAt" = NOW() WHERE "Id" = 547; -- Cũ: AM 3451
UPDATE "Products" SET "Sku" = 'AMY010', "UpdatedAt" = NOW() WHERE "Id" = 548; -- Cũ: AM 5039

-- Bước 3: Đồng bộ lại cột Sku lưu trữ trong bảng ImportVoucherItems (nếu có phiếu nhập)
UPDATE "ImportVoucherItems" ivi
SET "Sku" = p."Sku"
FROM "Products" p
WHERE ivi."ProductId" = p."Id" AND ivi."Sku" <> p."Sku";

COMMIT;
