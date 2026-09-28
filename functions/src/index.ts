import {setGlobalOptions} from "firebase-functions";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import Anthropic from "@anthropic-ai/sdk";
import {z} from "zod";
import {zodOutputFormat} from "@anthropic-ai/sdk/helpers/zod";

setGlobalOptions({maxInstances: 10});

// 등록해둔 키 참조.
const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");

// 이미지 데이터 타입 — Anthropic API가 허용하는 이미지 형식만.
type ImageMediaType = "image/jpeg" | "image/png" | "image/gif" | "image/webp";

// AI가 반드시 이 모양으로만 답하도록 하는 스키마.
const MealAnalysisSchema = z.object({
  name: z.string(),
  kcal: z.number().int(),
  protein_g: z.number(),
  carb_g: z.number(),
  fat_g: z.number(),
  fiber_g: z.number(),
  sodium_mg: z.number(),
  sugar_g: z.number(),
  calcium_mg: z.number(),
  iron_mg: z.number(),
  confidence: z.number().min(0).max(1), // 낮을수록 자신이 없다.
  needs_review: z.boolean(),
});

export const analyzeMealPhoto = onCall(
  {secrets: [anthropicApiKey]}, // 이 함수에서만 시크릿을 꺼내 쓸 수 있게 허용
  async (request) => {
    const {imageBase64, mediaType, bowl} = request.data as {
      imageBase64: string;
      mediaType: string; // 예: "image/jpeg"
      bowl?: { name: string; capacityMl: number };
    };

    if (!imageBase64) {
      throw new HttpsError("invalid-argument", "imageBase64가 필요해요.");
    }

    const client = new Anthropic({apiKey: anthropicApiKey.value()});

    const bowlHint = bowl ?
      `이 음식은 "${bowl.name}"(용량 ${bowl.capacityMl}ml) 그릇에 담겨 있어요. ` +
      "이 크기를 기준으로 양을 가늠해줘." :
      "";

    const response = await client.messages.parse({
      model: "claude-sonnet-5",
      max_tokens: 1024,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: {
                type: "base64",
                media_type: mediaType as ImageMediaType,
                data: imageBase64,
              },
            },
            {
              type: "text",
              text:
                `이 사진 속 음식을 분석해줘. ${bowlHint} ` +
                "칼로리와 3대 영양소(단백질·탄수화물·지방)뿐 아니라 " +
                "식이섬유(g), 나트륨(mg), 당류(g), 칼슘(mg), 철분(mg)도 " +
                "음식 종류와 양을 근거로 함께 추정해줘. " +
                "확실하지 않으면 추측해서 자신있게 답하지 말고, " +
                "confidence를 낮게 주고 needs_review를 true로 표시해줘.",
            },
          ],
        },
      ],
      output_config: {format: zodOutputFormat(MealAnalysisSchema)},
    });

    if (!response.parsed_output) {
      throw new HttpsError("internal", "AI 응답을 해석하지 못했어요.");
    }

    return response.parsed_output;
  }
);

// 식단 추천 하나의 모양 — 화면의 MealSuggestion과 필드를 맞췄다.
const MealSuggestionSchema = z.object({
  name: z.string(),
  emoji: z.string(),
  kcal: z.number().int(),
  meta: z.string(), // 한 줄 설명 (예: "현미밥 1공기 · 두부구이 120g")
  covers: z.array(z.string()), // 이 메뉴가 채워주는 영양소 (needs 중 실제 해당하는 것만)
  prefs: z.array(z.string()), // 이 메뉴가 맞는 선호 태그
  meals: z.array(z.string()), // 어울리는 끼니 (아침/점심/저녁/간식)
  tag: z.string(), // 짧은 분류 태그
  why: z.string(), // 추천 이유
  score: z.number().int().min(0).max(100), // 조건에 얼마나 잘 맞는지
});

const MealRecommendationSchema = z.object({
  recommendations: z.array(MealSuggestionSchema),
});

export const recommendMeals = onCall(
  {secrets: [anthropicApiKey]},
  async (request) => {
    const {needs, recMeal, recPrefs, recMaxKcal} = request.data as {
      needs: string[];
      recMeal: string;
      recPrefs: string[];
      recMaxKcal: number;
    };

    const client = new Anthropic({apiKey: anthropicApiKey.value()});

    const needsHint = needs.length > 0 ?
      `부족한 영양소(${needs.join(", ")})를 채우는 메뉴를 우선해줘. ` : "";
    const prefsHint = recPrefs.length > 0 ?
      `이런 선호 조건도 고려해줘: ${recPrefs.join(", ")}. ` : "";

    const response = await client.messages.parse({
      model: "claude-sonnet-5",
      max_tokens: 2048,
      messages: [
        {
          role: "user",
          content:
            `한국인이 즐겨 먹는 ${recMeal} 식단을 4~6개 추천해줘. ` +
            `각 메뉴는 ${recMaxKcal}kcal 이하여야 해. ` +
            needsHint + prefsHint +
            "각 메뉴마다 어울리는 이모지, 한 줄 설명, 이 메뉴가 실제로 채워주는 " +
            "영양소, 맞는 선호 태그, 어울리는 끼니 시간대, 짧은 분류 태그, " +
            "추천 이유, 그리고 조건에 얼마나 잘 맞는지 0~100 점수를 같이 줘.",
        },
      ],
      output_config: {format: zodOutputFormat(MealRecommendationSchema)},
    });

    if (!response.parsed_output) {
      throw new HttpsError("internal", "AI 추천을 만들지 못했어요.");
    }

    return response.parsed_output;
  }
);
