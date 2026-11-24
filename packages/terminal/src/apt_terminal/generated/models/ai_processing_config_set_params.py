from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..models.ai_processing_config_set_params_output_mode import (
    AiProcessingConfigSetParamsOutputMode,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="AiProcessingConfigSetParams")


@_attrs_define
class AiProcessingConfigSetParams:
    """
    Attributes:
        temperature (float | Unset):
        max_output_tokens (int | Unset):
        timeout_ms (int | Unset):
        output_mode (AiProcessingConfigSetParamsOutputMode | Unset):
    """

    temperature: float | Unset = UNSET
    max_output_tokens: int | Unset = UNSET
    timeout_ms: int | Unset = UNSET
    output_mode: AiProcessingConfigSetParamsOutputMode | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        temperature = self.temperature

        max_output_tokens = self.max_output_tokens

        timeout_ms = self.timeout_ms

        output_mode: str | Unset = UNSET
        if not isinstance(self.output_mode, Unset):
            output_mode = self.output_mode.value

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if temperature is not UNSET:
            field_dict["temperature"] = temperature
        if max_output_tokens is not UNSET:
            field_dict["max_output_tokens"] = max_output_tokens
        if timeout_ms is not UNSET:
            field_dict["timeout_ms"] = timeout_ms
        if output_mode is not UNSET:
            field_dict["output_mode"] = output_mode

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        temperature = d.pop("temperature", UNSET)

        max_output_tokens = d.pop("max_output_tokens", UNSET)

        timeout_ms = d.pop("timeout_ms", UNSET)

        _output_mode = d.pop("output_mode", UNSET)
        output_mode: AiProcessingConfigSetParamsOutputMode | Unset
        if isinstance(_output_mode, Unset):
            output_mode = UNSET
        else:
            output_mode = AiProcessingConfigSetParamsOutputMode(_output_mode)

        ai_processing_config_set_params = cls(
            temperature=temperature,
            max_output_tokens=max_output_tokens,
            timeout_ms=timeout_ms,
            output_mode=output_mode,
        )

        return ai_processing_config_set_params
