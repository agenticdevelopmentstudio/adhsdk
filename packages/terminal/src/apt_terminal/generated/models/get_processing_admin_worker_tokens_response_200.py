from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.ai_processing_worker_token import AiProcessingWorkerToken


T = TypeVar("T", bound="GetProcessingAdminWorkerTokensResponse200")


@_attrs_define
class GetProcessingAdminWorkerTokensResponse200:
    """
    Attributes:
        worker_tokens (list[AiProcessingWorkerToken]):
    """

    worker_tokens: list[AiProcessingWorkerToken]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        worker_tokens = []
        for worker_tokens_item_data in self.worker_tokens:
            worker_tokens_item = worker_tokens_item_data.to_dict()
            worker_tokens.append(worker_tokens_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "workerTokens": worker_tokens,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ai_processing_worker_token import AiProcessingWorkerToken

        d = dict(src_dict)
        worker_tokens = []
        _worker_tokens = d.pop("workerTokens")
        for worker_tokens_item_data in _worker_tokens:
            worker_tokens_item = AiProcessingWorkerToken.from_dict(worker_tokens_item_data)

            worker_tokens.append(worker_tokens_item)

        get_processing_admin_worker_tokens_response_200 = cls(
            worker_tokens=worker_tokens,
        )

        get_processing_admin_worker_tokens_response_200.additional_properties = d
        return get_processing_admin_worker_tokens_response_200

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
